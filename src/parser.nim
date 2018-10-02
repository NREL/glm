import json
import strutils
import strformat

import lexer
import tokens
import ast

type
    Parser* = ref object
        lexer*: Lexer
        current*: int
        tokens*: seq[Token]
        ast*: AST
    ParserError = object of Exception

proc initParser*(data: string): Parser =
    var l = initLexer(data)
    discard l.scanTokens()
    var p = Parser(
        lexer: l,
        current: 0,
        tokens: l.tokens,
        ast: AST(
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
        reportError(t, p.lexer.source)
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
            reportError(p.peek(), p.lexer.source)
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
        reportError(t, p.lexer.source)
        raise newException(ParserError, "Failed to parse module.")

proc parse_class(p: var Parser): Class=
    assert p.previous().kind == tk_class

    let t_class= p.advance(tk_newline, tk_space)
    var class_name = t_class.lexeme

    let t = p.advance(tk_space, tk_newline)

    if t.kind == tk_left_brace:
        var o = newJObject()
        var c = Class(name: class_name, attributes: o)

        while p.advance(tk_newline, tk_space).kind != tk_right_brace:
            var t = p.previous()
            assert p.match(tk_space)
            let lvalue = t.lexeme
            let rvalue = p.parse_rvalue()
            o.add(lvalue, newJString(rvalue))

        p.ignore(tk_semicolon)

        return c
    else:
        reportError(t, p.lexer.source)
        raise newException(ParserError, fmt"Failed to parse class. Expected {{ but found {t.lexeme}")


proc parse_object(p: var Parser): Object=
    assert p.previous().kind == tk_object

    let t_object = p.advance(tk_newline, tk_space)
    var object_name = t_object.lexeme

    if p.peek().kind == tk_colon:
        p.advance()
        while p.peek().lexeme != " ":
            object_name = object_name & ":" & p.advance().lexeme

    let t = p.advance(tk_space, tk_newline)

    if t.kind == tk_left_brace:
        var o = newJObject()
        var m = Object(name: object_name, attributes: o)

        while p.advance(tk_newline, tk_space).kind != tk_right_brace:
            if p.previous().kind == tk_object:
                var child = p.parse_object()
                m.children.add(child)
                continue

            var t = p.previous()
            assert p.match(tk_space)
            let lvalue = t.lexeme
            let rvalue = p.parse_rvalue()

            o.add(lvalue, newJString(rvalue))

        p.ignore(tk_semicolon)

        return m
    else:
        reportError(t, p.lexer.source)
        raise newException(ParserError, fmt"Failed to parse object. Expected {{ but found {t.lexeme}")

proc parse_schedule(p: var Parser): Schedule =
    assert p.previous().kind == tk_schedule

    let t_schedule = p.advance(tk_newline, tk_space)
    var schedule_name = t_schedule.lexeme

    let t = p.advance(tk_space, tk_newline)

    if t.kind == tk_left_brace:

        var schedules: seq[string] = @[]

        # TODO: nested schedule blocks
        while p.advance(tk_newline, tk_space).kind != tk_right_brace:

            let rvalue = p.parse_rvalue()
            schedules.add(rvalue)

        p.ignore(tk_semicolon)

        let s = Schedule(name: schedule_name, values: schedules)

        return s
    else:
        reportError(t, p.lexer.source)
        raise newException(ParserError, "Failed to parse schedule.")

proc parse_include(p: var Parser): Include =
    assert p.previous().kind == tk_hash
    let t_include_type = p.advance(tk_newline, tk_space)
    p.expect(tk_space)
    p.advance(tk_newline, tk_space)
    var rvalue = p.parse_rvalue()
    let d = Include(value: rvalue)
    return d

proc parse_directive(p: var Parser): Directive =
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
        reportError(p.peek(), p.lexer.source)
        raise newException(ParserError, "Failed to parse directive.")

proc parse_definition(p: var Parser): Definition =
    assert p.previous().kind == tk_hash
    let t_definition_type = p.advance(tk_newline, tk_space)
    p.expect(tk_space)
    var name = p.advance().lexeme
    if p.peek().kind == tk_equal:
        p.advance(tk_newline, tk_space)
        var rvalue = p.parse_rvalue()
        let d = Definition(name: name, value: rvalue)
        return d
    else:
        reportError(p.peek(), p.lexer.source)
        raise newException(ParserError, "Failed to parse definition.")

proc walk*(p: var Parser) =
    # TODO: support gui
    # TODO: support custom classes? Might require writing a C/CPP parser!
    # TODO: support intrinsic objects?
    # TODO: support nested configuration objects

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

        elif t.kind == tk_schedule:
            var node = p.parse_schedule()
            p.ast.schedules.add(node)

        elif t.kind == tk_hash and p.peek().kind == tk_directive:
            var node = p.parse_directive()
            p.ast.directives.add(node)

        elif t.kind == tk_hash and p.peek().kind == tk_definition:
            var node = p.parse_definition()
            p.ast.definitions.add(node)

        elif t.kind == tk_hash and p.peek().kind == tk_include:
            var node = p.parse_include()
            p.ast.includes.add(node)

        elif t.kind == tk_class:
            var node = p.parse_class()
            p.ast.classes.add(node)

        elif t.kind == tk_eof:
            break

        else:
            # echo p.current
            # for i, t in p.tokens:
                # echo i, " ", t
            reportError(t, p.lexer.source)
            raise newException(ParserError, "Unknown token encountered")

if isMainModule:

    var p = initParser(readFile("./tests/data/IEEE_13_Node_Test_Feeder.glm"))
    p.walk()
    echo p.ast

