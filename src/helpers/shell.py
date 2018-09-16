import os, subprocess, shlex
from functools import reduce

class _bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    def ok(text):
        return _bcolors.OKGREEN + text + _bcolors.ENDC
    def bold(text):
        return _bcolors.BOLD + text + _bcolors.ENDC
    def warning(text):
        return _bcolors.WARNING + text + _bcolors.ENDC
    def error(text):
        return _bcolors.FAIL + text + _bcolors.ENDC

class _CommandDefinition:
    def __init__(self, command):
        self.command = command

class _ScriptDefinition:
    def __init__(self, json):
        self._json  = json
        self._script = json["script"] if "script" in json else None
        self.lines = self._get_lines()
    
    def _get_lines(self):
        if isinstance(self._script, str):
            yield self._script
        elif isinstance(self._script, list):
            for line in self._script:
                yield line
        else:
            raise StopIteration

class _CommandList:
    def __init__(self, json):
        self._commands = json
    
    @staticmethod
    def _command_or_script(command):
        if isinstance(command, str):
            return _CommandDefinition(command)
        return _ScriptDefinition(command)

    def iterate(self):
        if self._commands == None:
            raise StopIteration
        elif isinstance(self._commands, list):
            for command in self._commands:
                yield self._command_or_script(command)
        else:
            yield self._command_or_script(self._commands)

class _BaseDefinition(object):
    def __init__(self, json):
        self._json = json
        self.commands = _CommandList(self._get_json("commands")).iterate()

    def _get_json(self, key):
        return self._json[key] if key in self._json else None

class _ValidationDefinition(_BaseDefinition):
    def __init__(self, json):
        _BaseDefinition.__init__(self, json)
        self.expression = self._get_json("expression")
        self.message = self._get_json("message")
        self.resolution = _CommandList(self._get_json("resolution")).iterate()

class _ExecutionDefinition(_BaseDefinition):
    def __init__(self, json):
        _BaseDefinition.__init__(self, json)
        self.name = json["name"]
        self.validate = _ValidationDefinition(json["validate"]) if "validate" in json else None

class _Result:
    def __init__(self, success, output, error):
        self.success = success
        self.output = output
        self.error = error


def _execute_command(commandDefinition):
    command_line = shlex.split(commandDefinition.command) if isinstance(commandDefinition.command, str) else commandDefinition.command
    print(command_line)
    session = subprocess.Popen(command_line, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    output = []
    for line in session.stdout:
        decoded = line.decode("ascii").strip()
        print(decoded)
        output.append(decoded)
    
    error = []
    if session.stderr != None:
        for line in session.stderr:
            decoded = line.decode("ascii").strip()
            print(_bcolors.error(decoded))
            error.append(decoded)

    session.poll()    
    return _Result(session.returncode == 0 and len(error) == 0, output, error)


def _execute_script(scriptDefinition):
    command = ["bash", "-c"]
    script = ""
    for line in scriptDefinition.lines:
        script += line + " "
    command.append(script)
    return _execute_command(_CommandDefinition(command))


def _validate(validateDefinition):
    if validateDefinition == None:
        return _Result(True, [], [])

    print(_bcolors.warning("Validating..."))
    results = _execute_commands(validateDefinition.commands)

    result = _Result(True, [], [])
    for validationResult in results:
        result.success &= validationResult.success
        result.output.append(validationResult.output)
        result.error.append(validationResult.error)
    return result
    

def _execute_commands(commandList):
    for command in commandList:
        if isinstance(command, _CommandDefinition):
            yield _execute_command(command)
        elif isinstance(command, _ScriptDefinition):
            yield _execute_script(command)
        else:
            print(_bcolors.error("Unknown instrunction type: " + type(command)))
            yield _Result(False, [], [])

def process_validate(json):
    execution_definition = _ExecutionDefinition(json)
    print("Excuting:", _bcolors.bold(execution_definition.name))
    for result in _execute_commands(execution_definition.commands):
        if not result.success:
            print(_bcolors.error("ERROR!"))
        
    result = _validate(execution_definition.validate)
    if result.success:
        print(_bcolors.ok("Completed successfully!"))
    else:
        print(_bcolors.error("ERROR!"))
        for error in result.error:
            print(error)
        