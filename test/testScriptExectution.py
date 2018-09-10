#! /usr/bin/python3

import subprocess
import os

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def cleanOutput(output):
    return output.decode("ascii").strip()

def printOutput(stdout, stderr):
    if stderr != None:
        print("ERROR:", cleanOutput(stderr))
    print(cleanOutput(stdout))

def executeAndPrint(session):
    print(bcolors.OKBLUE + "Executing:" + bcolors.ENDC, " ".join(session.args) if isinstance(session.args, list) else session.args)
    for line in session.stdout:
        print(cleanOutput(line))
    session.poll()
    print((bcolors.OKGREEN if session.returncode != 1 else bcolors.FAIL) + "Execution complete with return code:", session.returncode, bcolors.ENDC)

def process(script, scope_env=None):
    if isinstance(script, str):
        script = script.split(" ")
    session = subprocess.Popen(script, stdout=subprocess.PIPE) if scope_env == None else subprocess.Popen(script, stdout=subprocess.PIPE, env=scope_env)
    executeAndPrint(session)
    print()

process(["echo", "hello, me here!"])
process("./forscript.sh")
process("sudo service --status-all")
process("./testerror.sh")

# var_env = os.environ.copy()
# var_env["THEKEY"] = "TheValue"
# process("./testenv.sh", scope_env=var_env)
os.environ["THEKEY"] = "TheValue"
process("./testenv.sh", scope_env=os.environ)