import ../src/lexer
import ../src/tokens

when isMainModule:
    import unittest

    suite "test lexer":

        setup:
            var
                l = initLexer(readFile("./tests/data/4node.glm"))
                t = l.scanTokens()

        test "lexer":
            check:
                t[^1] of Token
                (t).len == 437
                t[^1].lexeme == "\0"
                t[^1].kind == tk_eof


