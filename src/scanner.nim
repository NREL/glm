import strformat

type
    Character* = object
        cargo, source_text: string
        source_index, line_index, column_index: int

proc `$`(c: Character): string =
    &"{c.line_index:>6}{c.column_index:>4}  {c.cargo}"


when isMainModule:

    let c = Character(
        cargo: "h",
        source_index: 0,
        line_index: 0,
        column_index: 0,
        source_text: "hello world"
    )

    echo $c
