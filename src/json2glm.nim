# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from utils import nil
from logging as logger import nil
import json
import nimpy

import ./ast

proc json2glm*(pathToFile: string, pretty = false): int =
    ## Convert from json to glm
    return 0


when isMainModule and appType != "lib":
    import cligen
    import os
    const versionString = staticExec("git describe --tags HEAD")
    dispatch(json2glm, version=("version", "glm (" & versionString & ")"))



