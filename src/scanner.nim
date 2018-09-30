import strformat
import strutils

const ENDMARK = '\0'
const NEWLINE = '\n'
const TAB = '\t'

type
    Character* = ref object
        cargo*: char
        source_text*: string
        source_index*, line_index*, column_index*: int

proc `$`*(c: Character): string =
    var cargo: string
    if c.cargo == NEWLINE:
        cargo = r"\n"
    elif c.cargo == TAB:
        cargo = r"\t"
    else:
        cargo = $c.cargo
    &"{c.line_index:>6}{c.column_index:>4}  {cargo:<2} {c.source_index}"

type
    Scanner* = ref object
        source_text: string
        source_index, last_index, line_index, column_index: int

proc reportError*(c: Character) =

    let line_index= c.line_index
    var source_text = c.source_text.splitLines()[line_index - 1]

    var start_index = c.column_index

    echo &"Parsing error on line: {line_index}"
    echo source_text
    let ntabs = source_text.count('\t')
    echo "^".align((ntabs * 8) + start_index)

proc initScanner*(source_text: string): Scanner =
    return Scanner(
        source_text: source_text,
        source_index: -1,
        last_index: len(source_text),
        line_index: 1,
        column_index: -1,
    )

proc get*(s: var Scanner): Character =
    s.source_index += 1
    s.column_index += 1

    if s.source_index >= s.last_index:
        result = Character(
            cargo: ENDMARK,
            line_index: s.line_index,
            column_index: s.column_index,
            source_index: s.source_index,
            source_text: s.source_text,
        )
    else:
        result = Character(
            cargo: s.source_text[s.source_index],
            line_index: s.line_index,
            column_index: s.column_index,
            source_index: s.source_index,
            source_text: s.source_text,
        )
    if s.source_index < s.last_index and s.source_text[s.source_index] == NEWLINE:
        s.line_index += 1
        s.column_index = -1


proc characters*(s: var Scanner): seq[Character] =
    while true:
        let c = s.get()
        result.add(c)
        if c.cargo == ENDMARK:
            break

when isMainModule:

    var s = initScanner("""Hello world
        This is a test
    """)
    for c in s.characters:
        echo c

