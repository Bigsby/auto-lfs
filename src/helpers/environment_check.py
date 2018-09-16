import os, re, json
# import re

from .shell import process_validate

check = re.compile(r"(error)|(not found)", flags=re.IGNORECASE)
thisPath = os.path.dirname(os.path.realpath(__file__))

def _check_line(line):
    return "ERROR" not in line and "not found" not in line and "command not found" not in line


def check_env():
    with open("./config/environment_check.json") as f:
        data = json.load(f)
        for check in data:
            process_validate(check)
    # process(os.path.join(thisPath, "../scripts/version-check.sh"), error_check=_check_line)