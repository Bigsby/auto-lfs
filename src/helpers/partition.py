import os, json
from . import shell
from .config import load_json
from .models import EnvironmentDefinition, ExecutionDefinition, FileSystemTypes, Result


class _Definitions(object):
    def __init__(self, environment: EnvironmentDefinition):
        self.data = load_json("mounting.json")
        self.environment = environment

        self.check_mount_point = self._get_definition_from_list(
            "MOUNTPOINT_CHECK")
        self.create_mount_point = self._get_definition_from_list(
            "MOUNTPOINT_CREATE")
        self.create_file_system = self._get_definition_from_list(
            "FILESYSTEM_CREATE")
        self.check_partition = self._get_definition_from_list(
            "PARTITION_CHECK")
        self.create_partition = self._get_definition_from_list(
            "PARTITION_CREATE")
        self.mount_partition = self._get_definition_from_list(
            "PARTITION_MOUNT")
        self.check_partition.validate.expression = self.check_partition.validate.expression.replace(
            "FILESYSTEMS", "|".join(FileSystemTypes.names())).replace(
                "MOUNTPOINT", environment.mount)

    def _get_definition_from_list(self, name: str) -> ExecutionDefinition:
        return ExecutionDefinition(
            [i for i in self.data if i["name"] == name][0])


def create_mount(environment: EnvironmentDefinition, verbose: bool) -> Result:
    definitions = _Definitions(environment)
    # for now, just check if mount point exists and is empty

    return shell.process_validate(definitions.check_mount_point, {
        "MOUNTPOINT": environment.mount,
        "FILESYSTEM": environment.file_system.name,
        "PARTITION": environment.partition or ""
    }, verbose)
