#!/usr/bin/python3

import subprocess, shlex, re
from functools import reduce
from typing import Generator

from helpers.models import ExecutionDefinition, CommandDefinition, ValidationDefinition, Result, ScriptDefinition, CommandList


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


def _execute_command(commandDefinition: CommandDefinition,
                     verbose: bool) -> Result:
    command_line = shlex.split(commandDefinition.command) if isinstance(
        commandDefinition.command, str) else commandDefinition.command
    if verbose: print(command_line)
    session = subprocess.Popen(
        command_line, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    output = []
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


def _execute_script(scriptDefinition: ScriptDefinition,
                    verbose: bool) -> Result:
    command = ["bash", "-c"]
    script = ""
    for line in scriptDefinition.lines:
        if not str.endswith(line, ";"): line += ";"
        script += line
    command.append(script)
    return _execute_command(CommandDefinition(command), verbose)


# def _wrap_results(results: Generator[Result, None, None]) -> Result:
#     result = Result(True)
#     for inner_result in results:
#         result.success &= inner_result.success
#         result.addoutput(inner_result.output)
#         result.adderror(inner_result.error)
#     return result


def _validate(validateDefinition: ValidationDefinition,
              verbose: bool) -> Result:
    if validateDefinition == None:
        return Result(True)

    print(_bcolors.warning("Validating..."))
    result = Result.group(
        _execute_commands(validateDefinition.commands, verbose))

    if not result.success:
        return result

    if validateDefinition.expression:
        for output in result.output:
            result.success &= re.match(validateDefinition.expression,
                                       output) != None

    return result


def _execute_commands(commandList: CommandList,
                      verbose: bool) -> Generator[Result, None, None]:
    for command in commandList:
        if isinstance(command, CommandDefinition):
            yield _execute_command(command, verbose)
        elif isinstance(command, ScriptDefinition):
            yield _execute_script(command, verbose)
        else:
            yield Result(False, [],
                         ["Unknown instrunction type: " + type(command)])


def _resolve(commandList: CommandList, verbose: bool) -> Result:
    print(_bcolors.warning("Resolving..."))
    resolveResults = _execute_commands(commandList, verbose)
    return Result.group(resolveResults)


def print_error(message: str):
    print(_bcolors.error(message))


def print_sucess(message: str):
    print(_bcolors.ok(message))


def print_bold(message: str):
    print(_bcolors.bold(message))


def process_validate(executionDefinition: ExecutionDefinition,
                     verbose=False) -> Result:
    print(_bcolors.bold(executionDefinition.name))

    results = _execute_commands(executionDefinition.commands, verbose)
    result = Result.group(results)

    if not result.success:
        return result

    if not executionDefinition.validate:
        return result

    validationResult = _validate(executionDefinition.validate, verbose)
    if validationResult.success:
        return result

    print("Validation failed")
    if verbose:
        print(executionDefinition.validate)
        print(validationResult.output)

    if not executionDefinition.validate.resolution:
        return Result.group([result, validationResult])

    resolutionResult = _resolve(executionDefinition.validate.resolution,
                                verbose)
    if not resolutionResult.success:
        return Result.group([result, validationResult, resolutionResult])
    else:
        return resolutionResult
