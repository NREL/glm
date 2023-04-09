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

proc load(file: PyObject): PyObject {. exportpy, noinline .} =
    let py = pyBuiltinsModule()
    var data = try:
            py.open(file).read().to(string)
        except:
            file.read().to(string)
    var p = initParser(data)
    p.walk()
    return pyImport("json").loads($(p.ast.toJson()))

proc dumps(data: PyObject): string {. exportpy, noinline .} =
    let d = pyImport("json").dumps( data )
    parseJson(d.to(string)).toAst().toGlm()

proc dump(data: PyObject, file: PyObject): int {. exportpy, noinline .} =
    let glm = dumps(data)
    try:
        writeFile(file.to(string), glm)
    except:
        discard file.write(glm)
    return 0

proc version(): string {. exportpy, noinline .} =
    const versionString = "v0.4.4"
    return versionString
