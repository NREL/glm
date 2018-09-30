import json
import strformat
import typetraits

type
    GLDObj* = object of RootObj
    GLD* = ref GLDObj
    Clock* = ref object of GLD
        attributes*: JsonNode
    Module* = ref object of GLD
        name*: string
        attributes*: JsonNode
    Include* = ref object of GLD
        name*: string
    Object* = ref object of GLD
        name*: string
        attributes*: JsonNode
        children*: seq[Object]

    AST* = ref object
        includes*: seq[Include]
        clock*: Clock
        modules*: seq[Module]
        objects*: seq[Object]

proc `$`*(ast: AST): string =
    fmt"<AST(modules={ast.modules.len}, objects={ast.objects.len})>"

proc `$`*(p: GLD): string =
    if p of Module:
        var p = cast[Module](p)
        &"<{p.type}(name: \"{p.name}\", attr: {p.attributes.len})>"
    elif p of Object:
        var p = cast[Object](p)
        &"<{p.type}(name: \"{p.name}\", attr: {p.attributes.len})>"
    elif p of Clock:
        var p = cast[Clock](p)
        &"<{p.type}(attr: {p.attributes.len})>"
    else:
        &"<{p.type}()>"

proc toJson(o: Object): JsonNode =
    var gldJObject = newJObject()
    gldJObject.add("name", newJString(o.name))
    gldJObject.add("attributes", o.attributes)
    for o_child in o.children:
        gldJObject.add("children", o.toJson())
    return gldJObject

proc toJson(m: Module): JsonNode =
    var gldJObject = newJObject()
    gldJObject.add("name", newJString(m.name))
    gldJObject.add("attributes", m.attributes)
    return gldJObject

proc toJson(i: Include): JsonNode =
    var gldJObject = newJObject()
    gldJObject.add("name", newJString(i.name))
    return gldJObject

proc toJson*(ast: AST): JsonNode =

    var j = newJObject()
    var modulesArray = newJArray()
    var objectsArray = newJArray()
    var includesArray = newJArray()
    j.add("includes", includesArray)
    j.add("objects", objectsArray)
    j.add("modules", modulesArray)

    var gldJObject: JsonNode
    for m in ast.modules:
        gldJObject = m.toJson()
        modulesArray.add(gldJObject)

    for i in ast.includes:
        gldJObject = i.toJson()
        includesArray.add(gldJObject)

    for o in ast.objects:
        gldJObject = o.toJson()
        objectsArray.add(gldJObject)

    return j

