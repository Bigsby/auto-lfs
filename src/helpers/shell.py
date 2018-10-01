#!/usr/bin/python3

import subprocess, shlex, re, os, sys
from functools import reduce
from typing import Generator

from .models import ExecutionDefinition, CommandDefinition, ValidationDefinition, Result, ScriptDefinition, CommandList


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


def _execute_command(commandDefinition: CommandDefinition, vars: dict,
                     verbose: bool) -> Result:
    env = os.environ.copy()
    for key, value in vars.items():
        env[key] = value

    command_line = shlex.split(commandDefinition.command) if isinstance(
        commandDefinition.command, str) else commandDefinition.command
    if verbose:
        print(vars)
        print(command_line)

    session = subprocess.Popen(
        command_line, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env
    ) if commandDefinition.show_output == False else subprocess.Popen(
        command_line,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=env)

    if commandDefinition.show_output:
        while True:
            nextLine = session.stdout.readline()
            if nextLine == "" and session.poll() is not None:
                break
            print(nextLine.decode("utf-8").strip())

    output = []
    if session.stdout != None:
        for line in session.stdout:
            decoded = line.decode("utf-8").strip()
            if verbose: print(decoded)
            output.append(decoded)

    error = []
    if session.stderr != None:
        for line in session.stderr:
            decoded = line.decode("utf-8").strip()
            if verbose: print(_bcolors.error(decoded))
            error.append(decoded)

    session.poll()
    executionSuccess = session.returncode == 0 or session.returncode == None
    if not executionSuccess:
        error.append("Return Code: " + str(session.returncode))

    return Result(executionSuccess and len(error) == 0, output, error)


def _execute_script(scriptDefinition: ScriptDefinition, vars: dict,
                    verbose: bool) -> Result:
    command = ["bash", "-c"]
    script = ""
    for line in scriptDefinition.lines:
        if not str.endswith(line, ";"): line += ";"
        script += line
    command.append(script)
    return _execute_command(
        CommandDefinition(command, scriptDefinition.show_output), vars,
        verbose)


def _validate(validateDefinition: ValidationDefinition, vars: dict,
              verbose: bool) -> Result:
    if validateDefinition == None:
        return Result(True)

    print(_bcolors.warning("Validating..."))
    result = Result.group(
        _execute_commands(validateDefinition.commands, vars, verbose))

    if not result.success:
        return result

    if validateDefinition.expression:
        if len(result.output) == 0:
            return Result(False, [], ["No output"])
        for output in result.output:
            result.success &= re.match(validateDefinition.expression,
                                       output) != None

    return result


def _execute_commands(commandList: CommandList, vars: dict,
                      verbose: bool) -> Generator[Result, None, None]:
    for command in commandList:
        if isinstance(command, CommandDefinition):
            yield _execute_command(command, vars, verbose)
        elif isinstance(command, ScriptDefinition):
            yield _execute_script(command, vars, verbose)
        else:
            yield Result(False, [],
                         ["Unknown instrunction type: " + type(command)])


def _resolve(commandList: CommandList, vars: dict, verbose: bool) -> Result:
    print(_bcolors.warning("Resolving..."))
    resolveResults = _execute_commands(commandList, vars, verbose)
    return Result.group(resolveResults)


def print_error(message: str):
    print(_bcolors.error(message))


def print_sucess(message: str):
    print(_bcolors.ok(message))


def print_bold(message: str):
    print(_bcolors.bold(message))


def process_validate(executionDefinition: ExecutionDefinition,
                     vars: dict = {},
                     verbose=False) -> Result:
    print(_bcolors.bold(executionDefinition.name))

    results = _execute_commands(executionDefinition.commands, vars, verbose)
    result = Result.group(results)

    if not result.success:
        return result

    if not executionDefinition.validate:
        return result

    validationResult = _validate(executionDefinition.validate, vars, verbose)
    if validationResult.success:
        return result

    print("Validation failed")
    if verbose:
        print(executionDefinition.validate)
        print(validationResult.output)

    if len(list(executionDefinition.validate.resolution)) == 0:
        return Result.group([result, validationResult])

    resolutionResult = _resolve(executionDefinition.validate.resolution, vars,
                                verbose)
    if not resolutionResult.success:
        return Result.group([result, validationResult, resolutionResult])
    else:
        return resolutionResult
