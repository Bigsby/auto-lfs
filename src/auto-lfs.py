#!/usr/bin/python3

import argparse

from helpers import shell
from helpers.environment import check_env
from helpers.partition import create_mount
from helpers.models import EnvironmentDefinition, FileSystemTypes

_defaults = EnvironmentDefinition("/mnt/lfs", None, FileSystemTypes.ext4)


def main(args):
    environementCheckResult = check_env(args.verbose)
    if not environementCheckResult.success:
        shell.print_error("Host environment does not meet requirements.")
        print(len(environementCheckResult.error), "error(s) found.")
        for error in environementCheckResult.error:
            print(error)
    else:
        environmentDefinition=EnvironmentDefinition(
            args.mount,
            args.PARTITION,
            FileSystemTypes[args.file_system]
        )
        create_mount(environmentDefinition)


parser = argparse.ArgumentParser(
    prog="Auto-LFS", description="Automatically build Linux from scratch")
parser.add_argument(
    "-v", "--verbose", action="store_true", help="Print every invocation")
parser.add_argument(
    "-m",
    "--mount",
    default=_defaults.mount,
    type=str,
    help="the mount path to load the new system. Defaults to " +
    _defaults.mount)
parser.add_argument(
    "-fs",
    "--file-system",
    choices=FileSystemTypes.names(),
    default="ext4",
    help="the file system to use on the system partition. Defaults to " + str(
        _defaults.file_system))
parser.add_argument(
    "PARTITION", type=str, help="the partion to mount the new system path on")

args = parser.parse_args()

main(args)
