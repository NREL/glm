import strutils
import strformat
import scanner
import tokens
import tables
from utils import nil

type
    Token* = object
        lexeme: string
        kind: tokens.TokenKind

    Lexer* = object
        source*: seq[Character]
        tokens*: seq[Token]
        start*, current*: int

    LexerError* = object of Exception

const
  keywords = {
     "class"  : tk_class,
     "object" : tk_object,
     "false"  : tk_false,
     "true"   : tk_true,
     "clock"  : tk_clock,
     "module" : tk_module,
  }.toTable

proc advance(lex: var Lexer): Character =
    result = lex.source[lex.current]
    lex.current += 1

proc isAtEnd(lex: Lexer): bool =
  # Check if EOF reached
  return lex.current >= lex.source.len - 1

proc match(lex: var Lexer, expected: char): bool =
    result = true
    if lex.isAtEnd():
      result = false
    elif lex.source[lex.current].cargo != expected:
      result = false
    else:
      # Match found and increment position.
      # Group current & previous chars into a single tokenKind
      lex.current += 1

proc peek(lex: var Lexer): Character =
    # Returns the current char without moving to the next one
    result = lex.source[lex.current]

proc addToken(lex: var Lexer, s: string, token_kind: TokenKind) =
    lex.tokens.add(
        Token(
            lexeme: s,
            kind: token_kind
        )
    )

proc addToken(lex: var Lexer, c: char, token_kind: TokenKind) =
    addToken(lex, $c, token_kind)

proc isIdentifier(c: char): bool =
    return c.isAlphaNumeric or c == '_'

proc scanToken(lex: var Lexer) =
    var c: Character = lex.advance()
    case c.cargo:
        of '(':
            lex.addToken(c.cargo, tk_left_paren)
        of ')':
            lex.addToken(c.cargo, tk_right_paren)
        of '{':
            lex.addToken(c.cargo, tk_left_brace)
        of '}':
            lex.addToken(c.cargo, tk_right_brace)
        of ',':
            lex.addToken(c.cargo, tk_comma)
        of '.':
            lex.addToken(c.cargo, tk_period)
        of '-':
            lex.addToken(c.cargo, tk_minus)
        of '+':
            lex.addToken(c.cargo, tk_plus)
        of '*':
            lex.addToken(c.cargo, tk_star)
        of '/':
            if lex.match('/'):
                # This is a comment
                # advance to end of line
                while (not lex.isAtEnd() and lex.peek().cargo != '\n'):
                    discard lex.advance()
            else:
                lex.addToken(c.cargo, tk_slash)
        of ';':
            lex.addToken(c.cargo, tk_semicolon)
        of ':':
            lex.addToken(c.cargo, tk_colon)
        of '\'':
            lex.addToken(c.cargo, tk_singlequote)
        of '\"':
            lex.addToken(c.cargo, tk_doublequote)
        of '=':
            lex.addToken(c.cargo, tk_equal)
        of '\n':
            lex.addToken(c.cargo, tk_newline)
        of '\r', '\t', ' ':
            discard
        else:
            if isAlphaNumeric(c.cargo):
                var s: string
                s.add(c.cargo)
                while ( not lex.isAtEnd() and lex.peek().cargo.isIdentifier ):
                    c = lex.advance()
                    s.add(c.cargo)
                if keywords.contains(s):
                    var tk = keywords[s]
                    lex.addToken(s, tk)
                elif s.isDigit():
                    lex.addToken(s, tk_number)
                else:
                    lex.addToken(s, tk_string)
            else:
                let error = &"Unable to parse:\n  line  col c index\n{c}\n"
                raise newException(LexerError, error)

proc scanTokens(lex: var Lexer): seq[Token] =
    while not lex.isAtEnd():
        lex.scanToken()
        echo lex.source[lex.current]
    lex.tokens.add(
        Token(
            kind: tk_eof,
            lexeme: ""
        )
    )
    return lex.tokens

proc initLexer*(source: string): Lexer =
    # Create a new Lexer instance
    var s = scanner.initScanner(source)
    return Lexer(
        source: s.characters,
        tokens: @[],
        start: 0,
        current: 0,
    )

when isMainModule:

    var l = initLexer(readFile("./tests/data/4node.glm"))
    echo l.scanTokens()

