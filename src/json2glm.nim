# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from utils import nil
from logging as logger import nil
import json
import nimpy
import terminal

import ./lexer
import ./ast

proc json2glm*(pathToFile: string): int =
    ## Convert from json to glm
    try:
        let data = readFile(pathToFile)
        let jn = parseJson(data)
        stdout.write jn.toAst().toGlm()
        return 0
    except Exception as e:
        glm_echo "Hint: ", fgGreen, newline=false
        echo "Could not convert the JSON file to a GLM file. Check the JSON format or contact the developers at https://github.com/NREL/glm"
        echo getCurrentExceptionMsg()
        return 1


when isMainModule and appType != "lib":
    import cligen
    import os
    const versionString = staticExec("git describe --tags HEAD")
    dispatch(json2glm, version=("version", "glm (" & versionString & ")"))



