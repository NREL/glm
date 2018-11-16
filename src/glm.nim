# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from utils import nil
from logging as logger import nil
import json
import nimpy

import ./parser
import ./ast

proc loads(data: string): PyObject {. exportpy .} =
    var p = initParser(data)
    p.walk()
    return pyImport("json").loads($(p.ast.toJson()))

proc load(file: string): PyObject {. exportpy .} =
    var data = read_file(file)
    return loads(data)

proc dumps(data: PyObject): string {. exportpy .} =
    let jsdata = nimpy.toJson( data )
    jsdata.toAst().toGlm()

proc dump(data: PyObject, file): int {. exportpy .} =
    let jsdata = nimpy.toJson( data )
    let glm = jsdata.toAst().toGlm()
    writeFile(file, glm)


