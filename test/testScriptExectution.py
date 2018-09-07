#! /usr/bin/python3

import subprocess

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

def process(script):
    if isinstance(script, str):
        script = script.split(" ")
    session = subprocess.Popen(script, stdout=subprocess.PIPE)
    executeAndPrint(session)
    print()
    print()

process(["echo", "hello, me here!"])

script = "./forscript.sh"
process(script)

sudoScript = "sudo service --status-all"
process(sudoScript)

errorScript = "./testerror.sh"
process(errorScript)