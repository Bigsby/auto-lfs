#!/usr/bin/python3

import os, subprocess, shlex, re
from functools import reduce
from typing import Generator

from helpers.models import *


class _bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

    @staticmethod
    def ok(text):
        return _bcolors.OKGREEN + text + _bcolors.ENDC

    @staticmethod
    def bold(text):
        return _bcolors.BOLD + text + _bcolors.ENDC

    @staticmethod
    def warning(text):
        return _bcolors.WARNING + text + _bcolors.ENDC

    @staticmethod
    def error(text):
        return _bcolors.FAIL + text + _bcolors.ENDC


def _execute_command(commandDefinition: CommandDefinition) -> Result:
    command_line = shlex.split(commandDefinition.command) if isinstance(
        commandDefinition.command, str) else commandDefinition.command
    print(command_line)
    session = subprocess.Popen(
        command_line, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    output = []
    for line in session.stdout:
        decoded = line.decode("utf-8").strip()
        print(decoded)
        output.append(decoded)

    error = []
    if session.stderr != None:
        for line in session.stderr:
            decoded = line.decode("utf-8").strip()
            print(_bcolors.error(decoded))
            error.append(decoded)

    session.poll()
    return Result(session.returncode == 0 and len(error) == 0, output, error)


def _execute_script(scriptDefinition: ScriptDefinition) -> Result:
    command = ["bash", "-c"]
    script = ""
    for line in scriptDefinition.lines:
        script += line + " "
    command.append(script)
    return _execute_command(CommandDefinition(command))


def _wrap_results(results: Generator[Result, None, None]) -> Result:
    result = Result(True, [], [])
    for inner_result in results:
        result.success &= inner_result.success
        result.addoutput(inner_result.output)
        result.adderror(inner_result.error)
    return result


def _validate(validateDefinition: ValidationDefinition) -> Result:
    if validateDefinition == None:
        return Result(True, [], [])

    print(_bcolors.warning("Validating..."))
    result = _wrap_results(_execute_commands(validateDefinition.commands))

    if not result.success:
        return result

    if validateDefinition.expression:
        validationExpression = re.compile(validateDefinition.expression)
        for output in result.output:
            result.success &= validationExpression.match(output) != None

    return result


def _execute_commands(
        commandList: CommandList) -> Generator[Result, None, None]:
    for command in commandList:
        if isinstance(command, CommandDefinition):
            yield _execute_command(command)
        elif isinstance(command, ScriptDefinition):
            yield _execute_script(command)
        else:
            print(
                _bcolors.error("Unknown instrunction type: " + type(command)))
            yield Result(False, [], [])


def _resolve(commandList: CommandList) -> Result:
    print(_bcolors.warning("Resolving..."))
    resolveResults = _execute_commands(commandList)
    return _wrap_results(resolveResults)


def print_error(message: str):
    print(_bcolors.error(message))


def print_sucess(message: str):
    print(_bcolors.ok(message))


def process_validate(executionDefinition: ExecutionDefinition) -> Result:
    print(_bcolors.bold("Excuting: " + executionDefinition.name))

    results = _execute_commands(executionDefinition.commands)
    result = _wrap_results(results)

    if not result.success:
        return result

    if not executionDefinition.validate:
        return result

    validationResult = _validate(executionDefinition.validate)
    if validationResult.success:
        return result

    if not executionDefinition.validate.resolution:
        return _wrap_results([result, validationResult])

    resolutionResult = _resolve(executionDefinition.validate.resolution)
    return _wrap_results([result, validationResult, resolutionResult])
