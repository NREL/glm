import json
import strutils

import ./lexer
import ./tokens
import ./ast

type
    Parser* = object
        current*: int
        tokens*: seq[Token]
    ParserError = object of Exception

proc initParser(data: string): Parser =
    var l = initLexer(data)
    discard l.scanTokens()
    var p = Parser(
        current: 0,
        tokens: l.tokens
    )
    return p

proc previous(p: Parser): Token = p.tokens[p.current - 1]

proc peek(p: Parser): Token = p.tokens[p.current]

proc isAtEnd(p: Parser): bool = p.peek().kind == tk_eof

proc advance(p: var Parser, ignore: varargs[TokenKind]): Token {.discardable.} =
    result = p.tokens[p.current]
    if not p.isAtEnd():
        p.current += 1
    if ignore.contains(result.kind):
        result = p.advance(ignore)

proc check(p: Parser, kind: TokenKind): bool =
    if p.isAtEnd():
        return false
    return p.peek().kind == kind


proc match(p: var Parser, types: varargs[TokenKind]): bool =
    for kind in types:
        if p.check(kind):
            p.advance()
        return true
    return false


proc consumeMatching(p: var Parser, kind: TokenKind, message: string): Token =
    if p.check(kind):
        return p.advance()
    raise newException(ParserError, message)

proc parse_rvalue(p: var Parser): string =
    var rvalue : seq[string]

    while p.peek().kind != tk_semicolon:
      rvalue.add( p.advance().lexeme )

    return join(rvalue)

proc parse_clock(p: var Parser) =
    assert p.previous().kind == tk_clock
    assert p.advance(tk_newline, tk_space).kind == tk_left_brace

    let t = p.advance(tk_newline, tk_space)
    while t.kind != "tk_right_brace":
        let lvalue = t.lexeme
        let rvalue = p.parse_rvalue()

        if lvalue == "timestamp":
            # TODO: parse rvalue timestamp
            discard

        var o = newJObject()
        o.add(lvalue, rvalue)


proc walk(p: var Parser) =

    while not p.isAtEnd():
        var t = p.advance()

        if t.kind == tk_newline:
            continue

        if t.kind == tk_clock:
            p.parse_clock()


if isMainModule:

    var p = initParser(readFile("./tests/data/4node.glm"))
    p.walk()


