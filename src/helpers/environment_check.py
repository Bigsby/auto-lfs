import os
import re

from .shell import process

check = re.compile(r"(error)|(not found)", flags=re.IGNORECASE)
thisPath = os.path.dirname(os.path.realpath(__file__))


def _check_line(line):
    return check.match(line) == None


def check_env():
    process(os.path.join(thisPath, "../scripts/version-check.sh"), error_check=_check_line)