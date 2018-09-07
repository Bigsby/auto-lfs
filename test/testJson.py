#! /usr/bin/python3
import json

def printProp(data, prop):
    if prop in data:
        propValue = data[prop]
        propType = type(propValue)
        
        if isinstance(propValue, list):
            print(prop, propType.__name__ + ":")
            for item in propValue:
                print(item)
        else:
            print(prop, propType.__name__ + ":", propValue)
    else:
        print(prop, ": Not found!")


with open("./test.json") as f:
    data = json.load(f)

    printProp(data, "propString")
    printProp(data, "propInt")
    printProp(data, "propBool")
    printProp(data, "propNull")
    printProp(data, "inexistingProp")
    printProp(data, "propList")