import json as _json
from typing import Generator
from enum import Enum


class CommandDefinition:
    def __init__(self, command, show_output: bool = False):
        self.command = command
        self.show_output = show_output


class _BaseDefinition(object):
    def __init__(self, json):
        self._json = json

    def _get_json(self, key, default_value=None):
        return self._json[key] if key in self._json else default_value

    def __str__(self):
        return _json.dumps(self._json)


class _BaseCommandsDefinition(_BaseDefinition):
    def __init__(self, json):
        _BaseDefinition.__init__(self, json)
        self.commands = CommandList(self._get_json("commands")).iterate()


class ScriptDefinition(_BaseDefinition):
    def __init__(self, json):
        _BaseDefinition.__init__(self, json)
        self._script = self._get_json("script")
        self.show_output = self._get_json("show-output", False)
        self.lines = self._get_lines()

    def _get_lines(self):
        if isinstance(self._script, str):
            yield self._script
        elif isinstance(self._script, list):
            for line in self._script:
                yield line
        else:
            raise StopIteration


class CommandList:
    def __init__(self, json):
        self._commands = json

    @staticmethod
    def _command_or_script(command):
        if isinstance(command, str):
            return CommandDefinition(command)
        return ScriptDefinition(command)

    def iterate(self):
        if self._commands == None:
            raise StopIteration
        elif isinstance(self._commands, list):
            for command in self._commands:
                yield self._command_or_script(command)
        else:
            yield self._command_or_script(self._commands)


class ValidationDefinition(_BaseCommandsDefinition):
    def __init__(self, json):
        _BaseCommandsDefinition.__init__(self, json)
        self.expression = self._get_json("expression")
        self.message = self._get_json("message")
        self.resolution = CommandList(self._get_json("resolution")).iterate()


class ExecutionDefinition(_BaseCommandsDefinition):
    def __init__(self, json):
        _BaseCommandsDefinition.__init__(self, json)
        self.name = json["name"]
        self.validate = ValidationDefinition(
            json["validate"]) if "validate" in json else None
        self.break_on_fail = self._get_json("break_on_fail", True)
        self.fail_message = self._get_json("fail_message")
        #self.vars = {}

    # def addvar(self, key: str, value: str):
    #     self.vars[key] = value


class Result(object):
    def __init__(self, success: bool, output: list = None, error: list = None):
        self.success = success
        self.output = output if output != None else []
        self.error = error if error != None else []

    def addoutput(self, output):
        if isinstance(output, list):
            for iop in output:
                self.addoutput(iop)
        elif isinstance(output, str):
            self.output.append(output)

    def adderror(self, err):
        if isinstance(err, list):
            for ierr in err:
                self.adderror(ierr)
        elif isinstance(err, str):
            self.error.append(err)

    @staticmethod
    def group(results: Generator['Result', None, None]) -> 'Result':
        result = Result(True)
        for inner_result in results:
            result.success &= inner_result.success
            result.addoutput(inner_result.output)
            result.adderror(inner_result.error)
        return result


class FileSystemTypes(Enum):
    ext3 = 1
    ext4 = 0

    def __str__(self):
        return self.name

    @staticmethod
    def names():
        return list(map(lambda fs: fs.name, FileSystemTypes))

    @staticmethod
    def values():
        return list(map(lambda fs: fs.value, FileSystemTypes))


class EnvironmentDefinitionEncoder(_json.JSONEncoder):
    def default(self, obj):  # pylint: disable=E0202
        if isinstance(obj, EnvironmentDefinition):
            return {
                "mount": obj.mount,
                "partition": obj.partition,
                "file_system": obj.file_system
            }
        elif isinstance(obj, FileSystemTypes):
            return obj.name
        else:
            return _json.JSONEncoder().default(obj)


class EnvironmentDefinition(object):
    def __init__(self, mount: str, partition: str,
                 fileSystem: FileSystemTypes):
        self.mount = mount
        self.partition = partition
        self.file_system = fileSystem

    def print(self):
        for key, value in self.__dict__.items():
            print(key, "=", value)

    def __str__(self):
        return _json.dumps(self, cls=EnvironmentDefinitionEncoder, indent=2)
