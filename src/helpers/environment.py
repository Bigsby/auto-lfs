#!/usr/bin/python3

import os, json, sys

from helpers import shell
from helpers.models import ExecutionDefinition


def _check_line(line):
    return "ERROR" not in line and "not found" not in line and "command not found" not in line


def check_env():
    with open(
            os.path.dirname(os.path.abspath(__file__)) +
            "/../config/environment_check.json") as f:
        data = json.load(f)
        for execution_json in data:
            executionDefinition = ExecutionDefinition(execution_json)
            result = shell.process_validate(executionDefinition)

            if result.success:
                shell.print_sucess(executionDefinition.name + ": OK")
            else:
                shell.print_error("ERROR!")
                if executionDefinition.break_on_fail:
                    if executionDefinition.fail_message:
                        print(executionDefinition.fail_message)
                    sys.exit("0")
