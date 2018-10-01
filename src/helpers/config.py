import json, os


def load_json(filename):
    filePath = config_directory() + filename
    with open(filePath) as f:
        return json.load(f)


def config_directory():
    return os.path.dirname(os.path.abspath(__file__)) + "/../config/"