from .models import EnvironmentDefinition, ExecutionDefinition, Result
from .config import load_json, config_directory
from . import shell


def buid(environment: EnvironmentDefinition, verbose: bool):
    vars = {}
    vars["LFS"] = environment.mount
    vars["CONFIGDIRECTORY"] = config_directory()
    steps = load_json("steps.json")
    results = []
    for config in steps:
        step = ExecutionDefinition(config)
        if step.name == "STOP":
            return Result.group(results)

        results.append(shell.process_validate(step, vars, verbose))