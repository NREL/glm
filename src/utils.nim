from logging import nil

proc initLogger() =
    var L = logging.newConsoleLogger()
    logging.addHandler(L)


proc isAlpha*(c: char): bool =
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_' or c == '\''
