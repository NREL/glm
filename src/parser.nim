import json
import strutils
import strformat

import lexer
import tokens
import ast

type
    Parser* = ref object
        current*: int
        tokens*: seq[Token]
        ast*: AST
    ParserError = object of Exception

proc initParser*(data: string): Parser =
    var l = initLexer(data)
    discard l.scanTokens()
    var p = Parser(
        current: 0,
        tokens: l.tokens,
        ast: AST(
            includes: @[],
            modules: @[],
            objects: @[],
            directives: @[],
            clock: nil,
        )
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

proc ignore(p: var Parser, kind: TokenKind): Token {.discardable.} =
    while p.peek().kind == kind:
        p.advance()
    return p.previous()

proc expect(p: var Parser, kind: TokenKind): Token {.discardable.} =
    let t = p.advance()
    if t.kind == kind:
        return t
    else:
        reportError(t)
        raise newException(ParserError, &"Expected {kind}, but got {t.lexeme}")

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

proc parse_rvalue(p: var Parser): string =
    var rvalue : seq[string]

    while p.peek().kind != tk_semicolon:
        if p.peek().kind == tk_newline:
            reportError(p.peek())
            raise newException(ParserError, "Unexpected newline character. Expected semicolon.")
        rvalue.add( p.advance().lexeme )

    p.advance()

    return join(rvalue).strip(chars={'\'', '"', ' '})

proc parse_clock(p: var Parser): Clock =
    assert p.previous().kind == tk_clock
    p.ignore(tk_space)
    p.expect(tk_left_brace)

    var o = newJObject()

    while p.advance(tk_newline, tk_space).kind != tk_right_brace:

        var t = p.previous()
        assert p.match(tk_space)
        let lvalue = t.lexeme
        let rvalue = p.parse_rvalue()

        o.add(lvalue, newJString(rvalue))

    let c = Clock(attributes: o)
    return c

proc parse_module(p: var Parser): Module =
    assert p.previous().kind == tk_module

    let t_module = p.advance(tk_newline, tk_space)
    let module = t_module.lexeme

    let t = p.advance(tk_newline, tk_space)

    if t.kind == tk_semicolon:
        var o = newJObject()
        let m = Module(name: module, attributes: o)
        return m
    elif t.kind == tk_left_brace:

        var o = newJObject()

        while p.advance(tk_newline, tk_space).kind != tk_right_brace:

            var t = p.previous()
            assert p.match(tk_space)
            let lvalue = t.lexeme
            let rvalue = p.parse_rvalue()

            o.add(lvalue, newJString(rvalue))
        p.ignore(tk_semicolon)
        let m = Module(name: module, attributes: o)
        return m

    else:
        reportError(t)
        raise newException(ParserError, "Failed to parse module.")


proc parse_object(p: var Parser): Object=
    assert p.previous().kind == tk_object

    let t_object = p.advance(tk_newline, tk_space)
    var object_name = t_object.lexeme

    if p.peek().kind == tk_colon:
        p.advance()
        object_name = object_name & ":" & p.advance().lexeme

    let t = p.advance(tk_space, tk_newline)

    if t.kind == tk_left_brace:
        var o = newJObject()

        while p.advance(tk_newline, tk_space).kind != tk_right_brace:
            if p.previous().kind == tk_object:
                reportError(p.previous())
                raise newException(ParserError, "Nested objects unsupported")

            var t = p.previous()
            assert p.match(tk_space)
            let lvalue = t.lexeme
            let rvalue = p.parse_rvalue()

            o.add(lvalue, newJString(rvalue))

        p.ignore(tk_semicolon)

        let m = Object(name: object_name, attributes: o)
        return m
    else:
        reportError(t)
        raise newException(ParserError, "Failed to parse object.")

proc parse_directive(p: var Parser): Directive=
    assert p.previous().kind == tk_hash
    let t_directive_type = p.advance(tk_newline, tk_space)
    p.expect(tk_space)
    var name = p.advance().lexeme
    if p.peek().kind == tk_equal:
        p.advance(tk_newline, tk_space)
        var rvalue = p.parse_rvalue()
        let d = Directive(name: name, value: rvalue)
        return d
    else:
        reportError(p.peek())
        raise newException(ParserError, "Failed to parse directive.")

proc walk*(p: var Parser) =

    while not p.isAtEnd():
        var t = p.advance(tk_newline, tk_space)

        if t.kind == tk_clock:
            var node = p.parse_clock()
            p.ast.clock = node

        elif t.kind == tk_module:
            var node = p.parse_module()
            p.ast.modules.add(node)

        elif t.kind == tk_object:
            var node = p.parse_object()
            p.ast.objects.add(node)

        elif t.kind == tk_hash:
            var node = p.parse_directive()
            p.ast.directives.add(node)

        elif t.kind == tk_eof:
            break

        else:
            # echo p.current
            # for i, t in p.tokens:
                # echo i, " ", t
            reportError(t)
            raise newException(ParserError, "Unknown token encountered")

if isMainModule:

    var p = initParser(readFile("./tests/data/4node.glm"))
    p.walk()
    echo p.ast


