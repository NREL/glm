import json
import strutils
import strformat

import lexer
import tokens
import ast

import uuids

type
    Parser* = ref object
        lexer*: Lexer
        current*: int
        tokens*: seq[Token]
        ast*: AST
        filename*: string
        suppress_warning*: bool
    ParserError* = object of Exception

proc initParser*(data: string, suppress_warning: bool = true): Parser =
    var l = initLexer(data)
    discard l.scanTokens()
    var p = Parser(
        lexer: l,
        current: 0,
        tokens: l.tokens,
        ast: AST(
            clock: nil,
        ),
        filename: "",
        suppress_warning: suppress_warning,
    )
    return p

proc updateFilename(p: Parser, filename: string) =
    p.filename = filename

proc previous(p: Parser): Token = p.tokens[p.current - 1]

proc peek(p: Parser): Token = p.tokens[p.current]

proc isAtBegin(p: Parser): bool = p.current == 0
proc isAtEnd(p: Parser): bool = p.peek().kind == tk_eof

proc recede(p: var Parser, ignore: varargs[TokenKind]): Token {.discardable.} =
    if not p.isAtBegin():
        p.current -= 1
        result = p.tokens[p.current]
        if ignore.contains(result.kind):
            result = p.recede(ignore)
    else:
        result = p.tokens[p.current]

proc advance(p: var Parser, ignore: varargs[TokenKind]): Token {.discardable.} =
    if not p.isAtEnd():
        result = p.tokens[p.current]
        p.current += 1
        if ignore.contains(result.kind):
            result = p.advance(ignore)
    else:
        result = p.tokens[p.current]

proc ignore(p: var Parser, kind: TokenKind): Token {.discardable.} =
    while p.peek().kind == kind:
        p.advance()
    return p.previous()

proc expect(p: var Parser, kind: TokenKind): Token {.discardable.} =
    let t = p.advance()
    if t.kind == kind:
        return t
    else:
        let hint = &"Unable to parse {p.filename}. Expected {kind}, but got {t.lexeme}"
        reportError(t, p.lexer.source, hint)
        raise newException(ParserError, hint)

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
        if p.peek().kind == tk_newline or p.peek().kind == tk_eof:
            let hint = &"Unable to parse {p.filename}. Unexpected newline character. Expected semicolon."
            reportError(p.previous(), p.lexer.source, hint)
            raise newException(ParserError, hint)
        rvalue.add( p.advance().lexeme )

    p.advance()

    return join(rvalue).strip(chars={'\'', '"', ' '})

proc parse_rvalue_with_optional_semicolon(p: var Parser): string =
    var rvalue : seq[string]

    while p.peek().kind != tk_semicolon:
        if p.peek().kind == tk_newline or p.peek().kind == tk_eof:
            let hint = &"Warning: Expected semicolon but found none."
            reportWarning(p.peek(), p.lexer.source, hint, p.suppress_warning)
            break
        rvalue.add( p.advance().lexeme )

    p.advance()

    return join(rvalue).strip(chars={'\'', '"', ' '})


proc parse_clock(p: var Parser): Clock =
    doAssert p.previous().kind == tk_clock
    p.ignore(tk_space)
    p.expect(tk_left_brace)

    var o = newJObject()

    while p.advance(tk_newline, tk_space).kind != tk_right_brace:

        var t = p.previous()
        doAssert p.match(tk_space)
        let lvalue = t.lexeme
        let rvalue = p.parse_rvalue()

        o.add(lvalue, newJString(rvalue))

    p.ignore(tk_semicolon)

    let c = Clock(attributes: o)
    return c

proc parse_module(p: var Parser): Module =
    doAssert p.previous().kind == tk_module

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
            doAssert p.match(tk_space)
            let lvalue = t.lexeme
            let rvalue = p.parse_rvalue()

            o.add(lvalue, newJString(rvalue))
        p.ignore(tk_semicolon)
        let m = Module(name: module, attributes: o)
        return m

    else:
        let hint = &"Unable to parse {p.filename}. Failed to parse module."
        reportError(t, p.lexer.source, hint)
        raise newException(ParserError, hint)

proc parse_class(p: var Parser): Class=
    doAssert p.previous().kind == tk_class

    let t_class= p.advance(tk_newline, tk_space)
    var class_name = t_class.lexeme

    let t = p.advance(tk_space, tk_newline)

    if t.kind == tk_left_brace:
        var o = newJObject()
        var c = Class(name: class_name, attributes: o)

        while p.advance(tk_newline, tk_space).kind != tk_right_brace:
            var t = p.previous()
            doAssert p.match(tk_space)
            let lvalue = t.lexeme
            let rvalue = p.parse_rvalue()
            o.add(lvalue, newJString(rvalue))

        p.ignore(tk_semicolon)

        return c
    else:
        let hint = fmt"Unable to parse {p.filename}. Failed to parse class. Expected {{ but found {t.lexeme}"
        reportError(t, p.lexer.source, hint)
        raise newException(ParserError, hint)


proc parse_object(p: var Parser): Object=
    doAssert p.previous().kind == tk_object

    let t_object = p.advance(tk_newline, tk_space)
    var object_name = t_object.lexeme

    if p.peek().kind == tk_period:
        p.advance()
        while p.peek().lexeme != " ":
            object_name = object_name & "." & p.advance().lexeme

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
            doAssert p.match(tk_space)
            let lvalue = t.lexeme
            if p.peek().kind == tk_object:
                p.advance()
                var child = p.parse_object()
                let name = $genUUID()
                child.attributes["name"] = newJString(name)
                p.ast.objects.add(child)
                o.add(lvalue, newJString(name))
            else:
                let rvalue = p.parse_rvalue()
                o.add(lvalue, newJString(rvalue))

        p.ignore(tk_semicolon)

        return m
    else:
        let hint = fmt"Unable to parse {p.filename}. Failed to parse object. Expected {{ but found {t.lexeme}"
        reportError(t, p.lexer.source, hint)
        raise newException(ParserError, hint)

proc parse_sub_schedule(p: var Parser): SubSchedule =
    doAssert p.previous().kind == tk_left_brace

    var schedules: seq[string] = @[]

    while p.advance(tk_newline, tk_space).kind != tk_right_brace:
        p.recede(tk_space)
        let rvalue = p.parse_rvalue_with_optional_semicolon()
        # if rvalue.splitWhitespace().len != 6:
            # let hint = &"Expected schedule of length 6 but got {rvalue.splitWhitespace().len} instead"
            # reportWarning(p.peek(), p.lexer.source, hint)
        schedules.add(rvalue)

    p.ignore(tk_semicolon)

    let s = SubSchedule(values: schedules)

    return s

proc parse_schedule(p: var Parser): Schedule =
    doAssert p.previous().kind == tk_schedule

    let t_schedule = p.advance(tk_newline, tk_space)
    var schedule_name = t_schedule.lexeme

    let t = p.advance(tk_space, tk_newline)

    if t.kind == tk_left_brace:

        var schedules: seq[string] = @[]
        var children: seq[SubSchedule] = @[]

        # TODO: nested schedule blocks
        while p.advance(tk_newline, tk_space).kind != tk_right_brace:

            if p.previous().kind == tk_left_brace:
                var child = p.parse_sub_schedule()
                children.add(child)
                continue

            p.recede(tk_space)
            let rvalue = p.parse_rvalue_with_optional_semicolon()
            # if rvalue.splitWhitespace().len != 6:
                # let hint = &"Expected schedule of length 6 but got {rvalue.splitWhitespace().len} instead"
                # reportWarning(p.peek(), p.lexer.source, hint)

            schedules.add(rvalue)

        p.ignore(tk_semicolon)

        let s = Schedule(name: schedule_name, values: schedules, children: children)

        return s
    else:
        let hint = &"Unable to parse {p.filename}. Failed to parse schedule."
        reportError(t, p.lexer.source, hint)
        raise newException(ParserError, hint)

proc parse_include(p: var Parser): Include =
    doAssert p.previous().kind == tk_hash
    let t_include_type = p.advance(tk_newline, tk_space)
    p.expect(tk_space)
    p.advance(tk_newline, tk_space)
    var rvalue = p.parse_rvalue()
    let d = Include(value: rvalue)
    return d

proc parse_directive(p: var Parser): Directive =
    doAssert p.previous().kind == tk_hash
    let t_directive_type = p.advance(tk_newline, tk_space)
    p.expect(tk_space)
    var name = p.advance().lexeme
    if p.peek().kind == tk_equal:
        p.advance(tk_newline, tk_space)
        var rvalue = p.parse_rvalue_with_optional_semicolon()
        let d = Directive(name: name, value: rvalue)
        return d
    else:
        let hint = &"Unable to parse {p.filename}. Failed to parse directive."
        reportError(p.peek(), p.lexer.source, hint)
        raise newException(ParserError, hint)

proc parse_definition(p: var Parser): Definition =
    doAssert p.previous().kind == tk_hash
    let t_definition_type = p.advance(tk_newline, tk_space)
    p.expect(tk_space)
    var name = p.advance().lexeme
    if p.peek().kind == tk_equal:
        p.advance(tk_newline, tk_space)
        var rvalue = p.parse_rvalue_with_optional_semicolon()
        let d = Definition(name: name, value: rvalue)
        return d
    else:
        let hint = &"Unable to parse {p.filename}. Failed to parse definition."
        reportError(p.peek(), p.lexer.source, hint)
        raise newException(ParserError, hint)

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
            let hint = &"Unable to parse {p.filename}. Unknown token encountered"
            reportError(t, p.lexer.source, hint)
            raise newException(ParserError, hint)

if isMainModule:

    var p = initParser(readFile("./tests/data/IEEE_13_Node_Test_Feeder.glm"))
    p.walk()
    echo p.ast


