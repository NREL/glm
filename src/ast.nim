import json
import strformat
import typetraits

type
    GLDObj* = object of RootObj
        attributes*: JsonNode
    GLD* = ref GLDObj
    Clock* = ref object of GLD
    Module* = ref object of GLD
        name*: string
    Object* = ref object of GLD
        name*: string

    AST* = object
        objects*: seq[GLD]

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
        &"<{p.type}(attr: {p.attributes.len})>"


