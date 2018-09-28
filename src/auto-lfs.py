#!/usr/bin/python3

import sys
from helpers import shell
from helpers.environment import check_env


def main():
    environementCheckResult = check_env("-v" in sys.argv)
    if not environementCheckResult.success:
        shell.print_error("Host environment does not meet requirements.")
        print(len(environementCheckResult.error), "error(s) found.")
        for error in environementCheckResult.error:
            print(error)
        sys.exit(0)
    
    print("Ready to prepare system.")


main()
