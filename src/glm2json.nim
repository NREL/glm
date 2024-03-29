# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from utils import nil
from logging as logger import nil
import json
import nimpy
import terminal

import ./lexer
import ./parser
import ./ast

proc parse*(file: string, suppress_warning: bool = true): AST =
    var x = read_file(file)
    var p = initParser(x, suppress_warning)
    p.filename = file
    p.walk()
    return p.ast

proc glm2json*(pathToFile: string, pretty = false, warn = true): int =
    ## Convert from glm to json

    # logger.info("Running main procedure.")
    # logger.debug("Received path_to_file: " & path_to_file)
    try:
        var ast = parse(path_to_file, warn)
        if pretty:
            stdout.write ast.toJson().pretty(), "\n"
        else:
            stdout.write ast.toJson(), "\n"
        return 0
    except Exception as e:
        glm_echo "Error: ", fgRed, newline=false
        glm_echo "Could not convert the GLM file to a JSON file. Check the GLM format or contact the developers at https://github.com/NREL/glm"
        glm_echo getCurrentExceptionMsg()
        return 1


when isMainModule and appType != "lib":
    import cligen
    import os
    const versionString = staticExec("git describe --tags HEAD")
    clCfg.version = versionString
    dispatch glm2json

