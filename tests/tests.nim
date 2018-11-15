import ../src/lexer
import ../src/tokens
import ../src/glm2json
import ../src/ast

import json

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

    suite "test 4node":

        setup:
            var
                l1 = parse("./tests/data/4node.glm").toJson()
                l2 = parse("./tests/data/powerflow_IEEE_4node.glm").toJson()

        test "parser":
            check:
                l1 == readFile("./tests/data/4node.json").parseJson()
                l2 == readFile("./tests/data/powerflow_IEEE_4node.json").parseJson()


    suite "test IEEE-13":

        setup:
            var
                l1 = parse("./tests/data/IEEE-13.glm").toJson()
                l2 = parse("./tests/data/IEEE_13_Node_Test_Feeder.glm").toJson()
                l3 = parse("./tests/data/IEEE_13_Node_With_Houses.glm").toJson()

        test "parser":
            check:
                l1 == readFile("./tests/data/IEEE-13.json").parseJson()
                l2 == readFile("./tests/data/IEEE_13_Node_Test_Feeder.json").parseJson()
                l3 == readFile("./tests/data/IEEE_13_Node_With_Houses.json").parseJson()




