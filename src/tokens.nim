type
    TokenKind* = enum
        # Single-character tokens.
        tk_eof,
        tk_newline,
        tk_left_paren,
        tk_right_paren,
        tk_left_brace,
        tk_right_brace,
        tk_comma,
        tk_period,
        tk_minus,
        tk_plus,
        tk_semicolon,
        tk_colon,
        tk_slash,
        tk_star,
        tk_equal,
        tk_singlequote,
        tk_doublequote,
        # Literals.
        tk_identifier,
        tk_string,
        tk_number,
        # glm constructs
        tk_clock
        tk_object
        tk_module
