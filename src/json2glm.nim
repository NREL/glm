# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from utils import nil
from logging as logger import nil
import json
import nimpy

import ./ast

proc main*(pathToFile: string, pretty = false): int =
    ## Convert from json to glm
    return 0


when isMainModule and appType != "lib":
    import cligen
    import os
    const versionString = staticExec("git rev-parse --verify HEAD --short")
    dispatchGen(main,
              version = ("version", "json2glm (v0.1.0-dev " & versionString & ")"))
    if paramCount()==0:
        quit(dispatch_main(@["--help"]))
    else:
        quit(dispatch_main(commandLineParams()))


