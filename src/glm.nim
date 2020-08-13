# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from utils import nil
from logging as logger import nil
import json
import nimpy
import typetraits

pyExportModuleName("_glm")

import ./parser
import ./ast

proc loads(data: string): PyObject {. exportpy, noinline .} =
    var p = initParser(data)
    p.walk()
    return pyImport("json").loads($(p.ast.toJson()))

proc load(file: string): PyObject {. exportpy, noinline .} =
    var data = read_file(file)
    return loads(data)

proc dumps(data: PyObject): string {. exportpy, noinline .} =
    let d = pyImport("json").dumps( data )
    parseJson(d.to(string)).toAst().toGlm()

proc dump(data: PyObject, file: string): int {. exportpy, noinline .} =
    let glm = dumps(data)
    writeFile(file, glm)

proc version(): string {. exportpy, noinline .} =
    const versionString = "v0.4.2"
    return versionString
