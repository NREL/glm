import strutils
import strformat
import tokens
import tables
from utils import nil

const ENDMARK = '\0'
const NEWLINE = '\n'
const TAB = '\t'

type
    Token* = ref object
        start_index: int
        end_index: int
        line_index: int
        lexeme*: string
        kind*: tokens.TokenKind

    Lexer* = ref object
        source*: string
        tokens*: seq[Token]
        start*, current*: int
        column_index, line_index, last_index: int

    LexerError* = object of Exception

const
  keywords = {
     "class"   : tk_class,
     "object"  : tk_object,
     "false"   : tk_false,
     "true"    : tk_true,
     "clock"   : tk_clock,
     "module"  : tk_module,
     "set"     : tk_directive,
     "define"  : tk_definition,
     "schedule": tk_schedule,
     "include" : tk_include,
  }.toTable

proc `$`*(t: Token): string =
    var lexeme = t.lexeme
    if lexeme == "\n":
        lexeme = "\\n"
    elif lexeme == "\t":
        lexeme = "\\t"
    else:
        discard
    fmt"<Token(""{lexeme}"", {t.kind})>"

proc reportError*(t: Token, source: string) =
    let line_index= t.line_index

    var source_text = source.splitLines()[line_index - 1]

    var start_index = t.start_index
    let end_index = t.end_index
    var ntabs = source_text[0..start_index].count('\t')

    echo &"Error on line: {line_index}"
    echo source_text
    if start_index != end_index:
        echo "^".repeat( end_index - start_index ).align( (ntabs * 7) + end_index + 1 )
    else:
        echo "^".align( (ntabs * 7) + start_index + 1)

proc reportError*(lex: var Lexer, c: char) =
    # TODO: improve error reporting
    echo &"Unknown symbol : {c}"

proc previous(lex: Lexer, index = 1): char =
    if lex.current - index >= 0:
        result = lex.source[lex.current - index]

proc advance(lex: var Lexer): char =
    if lex.current < lex.last_index and lex.previous() == NEWLINE:
        lex.line_index += 1
        lex.column_index = -1
    result = lex.source[lex.current]
    lex.current += 1
    lex.column_index += 1

proc isAtEnd(lex: Lexer): bool =
  # Check if EOF reached
  return lex.current >= lex.source.len - 1

proc match(lex: var Lexer, expected: char): bool =
    result = true
    if lex.isAtEnd():
      result = false
    elif lex.source[lex.current] != expected:
      result = false
    else:
      # Match found and increment position.
      # Group current & previous chars into a single tokenKind
      lex.current += 1

proc peek(lex: var Lexer): char =
    # Returns the current char without moving to the next one
    result = lex.source[lex.current]

proc addToken(lex: var Lexer, s: string, token_kind: TokenKind, start_index: int, end_index: int, line_index: int) =
    lex.tokens.add(
        Token(
            lexeme: s,
            kind: token_kind,
            start_index: start_index,
            end_index: end_index,
            line_index: line_index,
        )
    )


proc addToken(lex: var Lexer, c: char, token_kind: TokenKind, start_index: int, end_index: int, line_index: int) =
    addToken(lex, $c, token_kind, start_index, end_index, line_index)

proc isIdentifier(c: char): bool =
    return c.isAlphaNumeric or c == '_'

proc scanToken(lex: var Lexer) =
    var c: char = lex.advance()
    case c:
        of '(':
            lex.addToken(c, tk_left_paren, lex.column_index, lex.column_index, lex.line_index)
        of ')':
            lex.addToken(c, tk_right_paren, lex.column_index, lex.column_index, lex.line_index)
        of '{':
            lex.addToken(c, tk_left_brace, lex.column_index, lex.column_index, lex.line_index)
        of '}':
            lex.addToken(c, tk_right_brace, lex.column_index, lex.column_index, lex.line_index)
        of '[':
            lex.addToken(c, tk_left_bracket, lex.column_index, lex.column_index, lex.line_index)
        of ']':
            lex.addToken(c, tk_right_bracket, lex.column_index, lex.column_index, lex.line_index)
        of ',':
            lex.addToken(c, tk_comma, lex.column_index, lex.column_index, lex.line_index)
        of '.':
            lex.addToken(c, tk_period, lex.column_index, lex.column_index, lex.line_index)
        of '-':
            lex.addToken(c, tk_minus, lex.column_index, lex.column_index, lex.line_index)
        of '+':
            lex.addToken(c, tk_plus, lex.column_index, lex.column_index, lex.line_index)
        of '^':
            lex.addToken(c, tk_caret, lex.column_index, lex.column_index, lex.line_index)
        of '|':
            lex.addToken(c, tk_pipe, lex.column_index, lex.column_index, lex.line_index)
        of '*':
            lex.addToken(c, tk_star, lex.column_index, lex.column_index, lex.line_index)
        of '%':
            lex.addToken(c, tk_percent, lex.column_index, lex.column_index, lex.line_index)
        of '#':
            lex.addToken(c, tk_hash, lex.column_index, lex.column_index, lex.line_index)
        of '$':
            lex.addToken(c, tk_dollar, lex.column_index, lex.column_index, lex.line_index)
        of '<':
            lex.addToken(c, tk_left_triangle_bracket, lex.column_index, lex.column_index, lex.line_index)
        of '>':
            lex.addToken(c, tk_right_triangle_bracket, lex.column_index, lex.column_index, lex.line_index)
        of '?':
            lex.addToken(c, tk_question, lex.column_index, lex.column_index, lex.line_index)
        of '\\':
            lex.addToken(c, tk_backslash, lex.column_index, lex.column_index, lex.line_index)
        of '/':
            if lex.peek() == '/' and lex.previous(2) != ':':
                # This is a comment
                # advance to end of line
                while (not lex.isAtEnd() and lex.peek() != '\n'):
                    discard lex.advance()
            else:
                lex.addToken(c, tk_slash, lex.column_index, lex.column_index, lex.line_index)
        of ';':
            lex.addToken(c, tk_semicolon, lex.column_index, lex.column_index, lex.line_index)
        of ':':
            lex.addToken(c, tk_colon, lex.column_index, lex.column_index, lex.line_index)
        of '\'':
            lex.addToken(c, tk_singlequote, lex.column_index, lex.column_index, lex.line_index)
        of '\"':
            lex.addToken(c, tk_doublequote, lex.column_index, lex.column_index, lex.line_index)
        of '=':
            lex.addToken(c, tk_equal, lex.column_index, lex.column_index, lex.line_index)
        of '\n':
            lex.addToken(c, tk_newline, lex.column_index, lex.column_index, lex.line_index)
        of ' ':
            lex.addToken(c, tk_space, lex.column_index, lex.column_index, lex.line_index)
        of '\r', '\t':
            discard
        else:
            if isAlphaNumeric(c):
                var s: string
                s.add(c)
                while ( not lex.isAtEnd() and lex.peek().isIdentifier ):
                    c = lex.advance()
                    s.add(c)
                if keywords.contains(s):
                    var tk = keywords[s]
                    lex.addToken(s, tk, lex.column_index - s.len, lex.column_index, lex.line_index)
                elif s.isDigit():
                    lex.addToken(s, tk_number, lex.column_index - s.len, lex.column_index, lex.line_index)
                else:
                    lex.addToken(s, tk_string, lex.column_index - s.len, lex.column_index, lex.line_index)
            else:
                var t = Token(
                    lexeme: $c,
                    kind: tk_eof,
                    start_index: lex.column_index,
                    end_index: lex.column_index,
                    line_index: lex.line_index,
                )
                reportError(t, lex.source)
                let error = &"Unable to parse character: {c}\n"
                raise newException(LexerError, error)

proc scanTokens*(lex: var Lexer): seq[Token] =
    while not lex.isAtEnd():
        lex.scanToken()
    lex.scanToken()
    lex.addToken(
        "\0",
        tk_eof,
        lex.column_index,
        lex.column_index,
        lex.line_index,
    )
    return lex.tokens

proc initLexer*(source: string): Lexer =
    # Create a new Lexer instance
    # var s = scanner.initScanner(source)
    return Lexer(
        source: source,
        tokens: @[],
        start: 0,
        current: 0,
        line_index: 1,
        column_index: -1,
        last_index: len(source)
    )

when isMainModule:

    var l = initLexer(readFile("./tests/data/4node.glm"))
    for t in l.scanTokens():
        echo t
        reportError(t, l.source)
        # if t.kind == tk_clock:
            # break

    # var l = initLexer("""#define stylesheet=http://gridlab-d.svn.sourceforge.net/viewvc/gridlab-d/trunk/core/gridlabd-2_0;//this is a comment""")
    # for t in l.scanTokens():
        # echo t
