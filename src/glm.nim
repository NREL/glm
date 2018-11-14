# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from utils import nil
from logging as logger import nil
import json
import nimpy

import ./parser
import ./ast

proc loads(model: string): string {. exportpy .} =
    var p = initParser(model)
    p.walk()
    return $(p.ast.toJson())

proc load(file: string): PyObject {. exportpy .} =
    var model = read_file(file)
    let x = loads(model)
    return pyImport("json").loads(x)


proc parse(file: string): AST =
    var x = read_file(file)
    var p = initParser(x)
    p.walk()
    return p.ast

