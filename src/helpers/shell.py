import subprocess
import os

class _bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


def printOutput(line, error_check):

    if error_check == None:
        print(line)
    elif error_check(line):
        print(line)
    else:
        print(_bcolors.FAIL + line + _bcolors.ENDC)


def executeAndPrint(session, error_check):
    print(_bcolors.OKBLUE + "Executing:" + _bcolors.ENDC, " ".join(session.args) if isinstance(session.args, list) else session.args)

    for line in session.stdout:
        printOutput(line.decode("ascii").strip(), error_check)

    session.poll()
    print((_bcolors.OKGREEN if session.returncode == 0 else _bcolors.FAIL) + "Execution complete with return code:", session.returncode, _bcolors.ENDC)


def process(script, scope_env=None, error_check=None):
    if isinstance(script, str):
        script = script.split(" ")
    session = subprocess.Popen(script, stdout=subprocess.PIPE) if scope_env == None else subprocess.Popen(script, stdout=subprocess.PIPE, env=scope_env)
    executeAndPrint(session, error_check)
    print()