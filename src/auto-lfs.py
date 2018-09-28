#!/usr/bin/python3

import sys
from helpers.environment import check_env


def main():
    check_env("-v" in sys.argv)


main()
