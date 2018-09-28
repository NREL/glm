import strformat
import scanner
import tokens
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

proc advance(lex: var Lexer): Character =
    result = lex.source[lex.current]
    lex.current += 1

proc isAtEnd(lex: Lexer): bool =
  # Check if EOF reached
  return lex.current >= lex.source.len

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

proc addToken(lex: var Lexer, token_kind: TokenKind) =
    lex.tokens.add(
        Token(
            lexeme: $token_kind,
            kind: token_kind
        )
    )

proc scanToken(lex: var Lexer) =
    var c: Character = lex.advance()
    case c.cargo:
        of '(':
            lex.addToken(tk_left_paren)
        of ')':
            lex.addToken(tk_right_paren)
        of '{':
            lex.addToken(tk_left_brace)
        of '}':
            lex.addToken(tk_right_brace)
        of ',':
            lex.addToken(tk_comma)
        of '.':
            lex.addToken(tk_period)
        of '-':
            lex.addToken(tk_minus)
        of '+':
            lex.addToken(tk_plus)
        of '*':
            lex.addToken(tk_star)
        of '/':
            if lex.match('/'):
                # This is a comment
                # advance to end of line
                while (not lex.isAtEnd() and lex.peek().cargo != '\n'):
                    discard lex.advance()
            else:
                lex.addToken(tk_slash)
        of ';':
            lex.addToken(tk_semicolon)
        of ':':
            lex.addToken(tk_colon)
        of '\'':
            lex.addToken(tk_singlequote)
        of '=':
            lex.addToken(tk_equal)
        of '\n':
            lex.addToken(tk_newline)
        of '\r', '\t', ' ':
            discard
        else:
            if utils.isAlpha(c.cargo):
                var s: string
                while (not lex.isAtEnd() and ( utils.isAlpha(lex.peek().cargo))):
                    c = lex.advance()
                    s.add(c.cargo)
                lex.addToken(tk_string)
            else:
                let error = &"Unable to parse:\n  line  col c index\n{c}\n"
                raise newException(LexerError, error)

proc scanTokens(lex: var Lexer): seq[Token] =
    while not lex.isAtEnd():
        lex.scanToken()
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

