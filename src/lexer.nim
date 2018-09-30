import strutils
import strformat
import scanner
import tokens
import tables
from utils import nil

type
    Token* = object
        characters*: seq[Character]
        lexeme*: string
        kind*: tokens.TokenKind

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

proc `$`*(t: Token): string =
    var lexeme = t.lexeme
    if lexeme == "\n":
        lexeme = "\\n"
    elif lexeme == "\t":
        lexeme = "\\t"
    else:
        discard
    fmt"<Token(""{lexeme}"", {t.kind})>"

proc reportError*(t: Token) =

    let line_index= t.characters[0].line_index
    var source_text = t.characters[0].source_text.splitLines()[line_index - 1]

    var start_index = t.characters[0].column_index
    let end_index = t.characters[^1].column_index

    echo &"Parsing error on line: {line_index}"
    echo source_text
    if start_index != end_index:
        echo "^".align(start_index-1) & "^".repeat(end_index - start_index + 1)
    else:
        echo "^".align(start_index)

    # echo source_text[start_index..end_index]

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

proc addToken(lex: var Lexer, s: string, token_kind: TokenKind, characters: seq[Character]) =
    lex.tokens.add(
        Token(
            lexeme: s,
            kind: token_kind,
            characters: characters
        )
    )

proc addToken(lex: var Lexer, c: char, token_kind: TokenKind, characters: seq[Character]) =
    addToken(lex, $c, token_kind, characters)

proc isIdentifier(c: char): bool =
    return c.isAlphaNumeric or c == '_'

proc scanToken(lex: var Lexer) =
    var c: Character = lex.advance()
    case c.cargo:
        of '(':
            lex.addToken(c.cargo, tk_left_paren, @[c])
        of ')':
            lex.addToken(c.cargo, tk_right_paren, @[c])
        of '{':
            lex.addToken(c.cargo, tk_left_brace, @[c])
        of '}':
            lex.addToken(c.cargo, tk_right_brace, @[c])
        of ',':
            lex.addToken(c.cargo, tk_comma, @[c])
        of '.':
            lex.addToken(c.cargo, tk_period, @[c])
        of '-':
            lex.addToken(c.cargo, tk_minus, @[c])
        of '+':
            lex.addToken(c.cargo, tk_plus, @[c])
        of '*':
            lex.addToken(c.cargo, tk_star, @[c])
        of '#':
            lex.addToken(c.cargo, tk_hash, @[c])
        of '/':
            if lex.match('/'):
                # This is a comment
                # advance to end of line
                while (not lex.isAtEnd() and lex.peek().cargo != '\n'):
                    discard lex.advance()
            else:
                lex.addToken(c.cargo, tk_slash, @[c])
        of ';':
            lex.addToken(c.cargo, tk_semicolon, @[c])
        of ':':
            lex.addToken(c.cargo, tk_colon, @[c])
        of '\'':
            lex.addToken(c.cargo, tk_singlequote, @[c])
        of '\"':
            lex.addToken(c.cargo, tk_doublequote, @[c])
        of '=':
            lex.addToken(c.cargo, tk_equal, @[c])
        of '\n':
            lex.addToken(c.cargo, tk_newline, @[c])
        of ' ':
            lex.addToken(c.cargo, tk_space, @[c])
        of '\r', '\t':
            discard
        else:
            if isAlphaNumeric(c.cargo):
                var s: string
                var characters: seq[Character] = @[]
                s.add(c.cargo)
                while ( not lex.isAtEnd() and lex.peek().cargo.isIdentifier ):
                    c = lex.advance()
                    s.add(c.cargo)
                    characters.add(c)
                if keywords.contains(s):
                    var tk = keywords[s]
                    lex.addToken(s, tk, characters)
                elif s.isDigit():
                    lex.addToken(s, tk_number, characters)
                else:
                    lex.addToken(s, tk_string, characters)
            else:
                reportError(c)
                let error = &"Unable to parse character:\n  line  col c  index\n{c}\n"
                raise newException(LexerError, error)

proc scanTokens*(lex: var Lexer): seq[Token] =
    while not lex.isAtEnd():
        lex.scanToken()
    lex.tokens.add(
        Token(
            kind: tk_eof,
            lexeme: "\0",
            characters: @[],
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

