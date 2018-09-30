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
        value*: string
    Object* = ref object of GLD
        name*: string
        attributes*: JsonNode
        children*: seq[Object]
    Class* = ref object of GLD
        name*: string
        attributes*: JsonNode
    Directive* = ref object of GLD
        name*: string
        value*: string
    Definition* = ref object of GLD
        name*: string
        value*: string
    Schedule* = ref object of GLD
        name*: string
        values*: seq[string]

    AST* = ref object
        clock*: Clock
        includes*: seq[Include]
        modules*: seq[Module]
        objects*: seq[Object]
        classes*: seq[Class]
        directives*: seq[Directive]
        definitions*: seq[Definition]
        schedules*: seq[Schedule]

proc `$`*(ast: AST): string =
    fmt"<AST(modules={ast.modules.len}, objects={ast.objects.len})>"

proc `$`*(p: GLD): string =
    if p of Module:
        var p = cast[Module](p)
        &"<{p.type}(name: \"{p.name}\", attr: {p.attributes.len})>"
    elif p of Object:
        var p = cast[Object](p)
        &"<{p.type}(name: \"{p.name}\", attr: {p.attributes.len})>"
    elif p of Class:
        var p = cast[Class](p)
        &"<{p.type}(name: \"{p.name}\", attr: {p.attributes.len})>"
    elif p of Clock:
        var p = cast[Clock](p)
        &"<{p.type}(attr: {p.attributes.len})>"
    elif p of Directive:
        var p = cast[Directive](p)
        &"<{p.type}(name: {p.name}, value: {p.value})>"
    elif p of Definition:
        var p = cast[Definition](p)
        &"<{p.type}(name: {p.name}, value: {p.value})>"
    elif p of Include:
        var p = cast[Include](p)
        &"<{p.type}(value: {p.value})>"
    elif p of Schedule:
        var p = cast[Schedule](p)
        &"<{p.type}(name: {p.name})>"
    else:
        &"<{p.type}()>"

proc toJson(o: Object): JsonNode =
    var gldJObject = newJObject()
    gldJObject.add("name", newJString(o.name))
    gldJObject.add("attributes", o.attributes)
    gldJObject.add("children", newJArray())
    for o_child in o.children:
        gldJObject["children"].add(o_child.toJson())
    return gldJObject

proc toJson(m: Module): JsonNode =
    var gldJObject = newJObject()
    gldJObject.add("name", newJString(m.name))
    gldJObject.add("attributes", m.attributes)
    return gldJObject

proc toJson(i: Include): JsonNode =
    var gldJObject = newJObject()
    gldJObject.add("value", newJString(i.value))
    return gldJObject

proc toJson(d: Directive): JsonNode =
    var gldJObject = newJObject()
    gldJObject.add("name", newJString(d.name))
    gldJObject.add("value", newJString(d.value))
    return gldJObject

proc toJson(d: Definition): JsonNode =
    var gldJObject = newJObject()
    gldJObject.add("name", newJString(d.name))
    gldJObject.add("value", newJString(d.value))
    return gldJObject

proc toJson(c: Clock): JsonNode =
    var gldJObject = newJObject()
    if not c.isNil:
        for k, v in c.attributes:
            gldJObject.add(k, v)
    return gldJObject

proc toJson(d: Schedule): JsonNode =
    var gldJObject = newJObject()
    var values = newJArray()
    gldJObject.add("name", newJString(d.name))
    for v in d.values:
        values.add(newJString(v))
    gldJObject.add("values", values)
    return gldJObject

proc toJson*(ast: AST): JsonNode =

    var j = newJObject()
    var modulesArray = newJArray()
    var objectsArray = newJArray()
    var includesArray = newJArray()
    var directivesArray = newJArray()
    var definitionsArray = newJArray()
    var schedulesArray = newJArray()

    j.add("clock", ast.clock.toJson())
    j.add("includes", includesArray)
    j.add("objects", objectsArray)
    j.add("modules", modulesArray)
    j.add("directives", directivesArray)
    j.add("schedules", schedulesArray)

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

    for d in ast.directives:
        gldJObject = d.toJson()
        directivesArray.add(gldJObject)

    for d in ast.definitions:
        gldJObject = d.toJson()
        definitionsArray.add(gldJObject)

    for s in ast.schedules:
        gldJObject = s.toJson()
        schedulesArray.add(gldJObject)

    return j

