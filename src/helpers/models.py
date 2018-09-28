class CommandDefinition:
    def __init__(self, command):
        self.command = command


class ScriptDefinition:
    def __init__(self, json):
        self._json = json
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


class _BaseDefinition(object):
    def __init__(self, json):
        self._json = json
        self.commands = CommandList(self._get_json("commands")).iterate()

    def _get_json(self, key, default_value=None):
        return self._json[key] if key in self._json else default_value


class ValidationDefinition(_BaseDefinition):
    def __init__(self, json):
        _BaseDefinition.__init__(self, json)
        self.expression = self._get_json("expression")
        self.message = self._get_json("message")
        self.resolution = CommandList(self._get_json("resolution")).iterate()


class ExecutionDefinition(_BaseDefinition):
    def __init__(self, json):
        _BaseDefinition.__init__(self, json)
        self.name = json["name"]
        self.validate = ValidationDefinition(
            json["validate"]) if "validate" in json else None
        self.break_on_fail = self._get_json("break", True)
        self.fail_message = self._get_json("fail_message")


class Result:
    def __init__(self, success, output, error):
        self.success = success
        self.output = output
        self.error = error   

    def addoutput(self, op):
        if isinstance(op, list):
            for iop in op:
                self.addoutput(iop)
        elif isinstance(op, str):
            self.output.append(op)

    def adderror(self, err):
        if isinstance(err, list):
            for ierr in err:
                self.adderror(ierr)
        elif isinstance(err, str):
            self.error.append(err)


