import json

from .models import EnvironmentDefinition, EnvironmentDefinitionEncoder, Result

def create_mount(environment: EnvironmentDefinition) -> Result:
    print("Mounting to partition...")

    environment.print()

    