import json
import strformat

type
    GLD* = ref object of RootObj
        attributes*: JsonNode
        kind*: string
    Clock* = ref object of GLD
    Module* = ref object of GLD
    Node* = ref object of GLD

    AST* = object
        objects*: ref seq[GLD]

proc `$`*(o: ref GLD): string =
    return &"<{o[].kind}: {o[].attributes.len}>"

proc initClock*(attributes: JsonNode): Clock =

    return Clock(kind: "clock", attributes: attributes)
