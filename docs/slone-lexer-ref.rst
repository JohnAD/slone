slone/lexer Reference
==============================================================================

The following are the references for slone/lexer.



Types
=====



.. _Token.type:
Token
---------------------------------------------------------

    .. code:: nim

        Token* = object
          row: int
          col: int
          case kind*: TokenKind
          of tkDocStart:
          of tkIndent:
          of tkString:
          of tkPunctuation:
          of tkSpace:


    source line: `47 <../src/slone/lexer.nim#L47>`__



.. _TokenKind.type:
TokenKind
---------------------------------------------------------

    .. code:: nim

        TokenKind* = enum
          tkDocStart
          tkIndent,
          tkString,
          tkPunctuation,
          tkSpace


    source line: `41 <../src/slone/lexer.nim#L41>`__







Procs, Methods, Iterators
=========================


.. _isTokenReady.p:
isTokenReady
---------------------------------------------------------

    .. code:: nim

        proc isTokenReady*(lex: LexerDetail): bool =

    source line: `210 <../src/slone/lexer.nim#L210>`__



.. _newLexer.p:
newLexer
---------------------------------------------------------

    .. code:: nim

        proc newLexer*(): LexerDetail =

    source line: `214 <../src/slone/lexer.nim#L214>`__



.. _popToken.p:
popToken
---------------------------------------------------------

    .. code:: nim

        proc popToken*(lex: var LexerDetail): Token =

    source line: `205 <../src/slone/lexer.nim#L205>`__



.. _scanRune.p:
scanRune
---------------------------------------------------------

    .. code:: nim

        proc scanRune*(lex: var LexerDetail, r: Rune) =

    source line: `99 <../src/slone/lexer.nim#L99>`__








Table Of Contents
=================

1. `Introduction to slone <https://github.com/JohnAD/slone>`__
2. Appendices

    A. `slone/lexer Reference <slone-lexer-ref.rst>`__
    B. `slone/reader Reference <slone-reader-ref.rst>`__
    C. `slone/writer Reference <slone-writer-ref.rst>`__
