# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from utils import nil
from logging as logger import nil
import json

import ./parser
import ./ast

proc read_string(file: string): string =
    let x = readFile(file)
    return x

proc parse(file: string): AST =
    var x = read_string(file)
    var p = initParser(x)
    p.walk()
    return p.ast

proc main*(path_to_file: string): int =
    logger.info("Running main procedure.")
    logger.debug("Received path_to_file: " & path_to_file)
    try:
        var ast = parse(path_to_file)
        echo ast.toJson().pretty()
    except:
        logger.error("Error occurred")
        echo("Unable to parse file: " & path_to_file)
        raise
    return 0


when isMainModule:
    import cligen
    cligen.dispatch(main)
