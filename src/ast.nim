import json
import strformat
import strutils
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
    SubSchedule* = ref object of GLD
        values*: seq[string]
    Schedule* = ref object of GLD
        name*: string
        values*: seq[string]
        children*: seq[SubSchedule]

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

proc toObject*(jn: JsonNode): Object =
    new result
    result.name = $(jn["name"])
    result.attributes = jn["attributes"]
    for child in jn["children"]:
        result.children.add(toObject(child))
    return result

proc toModule*(jn: JsonNode): Module =
    new result
    result.name = $(jn["name"])
    result.attributes = jn["attributes"]
    return result

proc toInclude*(jn: JsonNode): Include =
    new result
    result.value = $(jn["value"])
    return result

proc toDirective*(jn: JsonNode): Directive =
    new result
    result.name = $(jn["name"])
    result.value = $(jn["value"])
    return result

proc toDefinition*(jn: JsonNode): Definition =
    new result
    result.name = $(jn["name"])
    result.value = $(jn["value"])
    return result

proc toClock*(jn: JsonNode): Clock =
    new result
    result.attributes = jn
    return result

proc toSchedule*(jn: JsonNode): Schedule =
    new result
    result.name = $(jn["name"])
    for v in jn["values"]:
        result.values.add($(jn["values"]))
    # TODO: add subschedule support
    return result

proc toAst*(jn: JsonNode): AST =
    new result

    result.clock = jn["clock"].toClock()

    for json_node in jn["objects"]:
        result.objects.add json_node.toObject()
    for json_node in jn["modules"]:
        result.modules.add json_node.toModule()
    for json_node in jn["definitions"]:
        result.definitions.add json_node.toDefinition()
    for json_node in jn["directives"]:
        result.directives.add json_node.toDirective()
    for json_node in jn["schedules"]:
        result.schedules.add json_node.toSchedule()

    result

proc toGlmAttributes(jn: JsonNode): string =

    for key, val in jn:
        result = result & "\t" & key.strip(chars={'"'}) & " "
        if " " in $(val):
            result = result & ($val) & ";\n"
        else:
            result = result & ($val).strip(chars={'"'}) & ";\n"

proc toGlm*(ast: AST): string =
    result = result & "clock {\n"
    result = result & toGlmAttributes(ast.clock.attributes)
    result = result & "};"

    result = result & "\n\n"

    for directive in ast.directives:
        result = result & "#set " & directive.name.strip(chars={'"'}) & "=" & directive.value.strip(chars={'"'}) & ";\n"

    result = result & "\n"

    for definition in ast.definitions:
        result = result & "#define " & definition.name.strip(chars={'"'}) & "=" & definition.value.strip(chars={'"'}) & ";\n"

    result = result & "\n"

    for glm_include in ast.includes:
        result = result & "#include " & glm_include.value.strip(chars={'"'}) & ";\n"

    result = result & "\n"

    for schedule in ast.schedules:
        result = result & "schedule " & schedule.name.strip(chars={'"'}) & " {\n"
        for val in schedule.values:
            result = result & "\t" & val & ";\n"
        result = result & "};"
        result = result & "\n\n"

    result = result & "\n\n"

    for module in ast.modules:
        result = result & "module " & module.name.strip(chars={'"'}) & " {\n"
        result = result & toGlmAttributes(module.attributes)
        result = result & "};"
        result = result & "\n\n"

    result = result & "\n\n"

    for obj in ast.objects:
        result = result & "object " & obj.name.strip(chars={'"'}) & " {\n"
        result = result & toGlmAttributes(obj.attributes)
        result = result & "};"
        result = result & "\n\n"


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
    var children = newJArray()
    for child in d.children:
        var values = newJArray()
        for v in child.values:
            values.add(newJString(v))
        children.add(values)
    gldJObject.add("children", children)
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
    j.add("definitions", definitionsArray)
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

