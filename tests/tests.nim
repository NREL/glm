
import ../src/scanner
import ../src/lexer

when isMainModule:
    import unittest
    suite "test scanner":

        setup:
            var
                s = initScanner(readFile("./tests/data/4node.glm"))

        test "scanner":
            check:
                (s.characters).len == 1914
                s.characters[^1].cargo == '\0'

    suite "test lexer":

        setup:
            var
                l = initLexer(readFile("./tests/data/4node.glm"))
                t = l.scanTokens()

        test "lexer":
            check:
                t[^1] of Token
                (t).len == 361
                t[^1].lexeme == "\0"
                t[^1].kind==tk_eof


