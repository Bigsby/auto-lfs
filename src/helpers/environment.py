#!/usr/bin/python3

import os, json, sys

from helpers import shell
from helpers.getch import getch
from helpers.models import ExecutionDefinition, Result


def check_env(verbose: bool = False) -> Result:
    shell.print_bold("Checking host environment requirements...")
    results=[]
    print()
    with open(
            os.path.dirname(os.path.abspath(__file__)) +
            "/../config/environment_check.json") as f:
        data = json.load(f)
        for execution_json in data:
            executionDefinition = ExecutionDefinition(execution_json)
            result = shell.process_validate(executionDefinition, verbose)

            if result.success:
                shell.print_sucess(executionDefinition.name + ": OK")
            else:
                shell.print_error("ERROR!")
                for error in result.error:
                    print(error)
                if executionDefinition.break_on_fail:
                    if executionDefinition.fail_message:
                        print(executionDefinition.fail_message)
                    sys.exit("0")

                print("Do you want to continue (Y/n)?")
                option = getch()
                if option == "n": sys.exit("0")
            results.append(result)
            print()
    
    return Result.group(results)
