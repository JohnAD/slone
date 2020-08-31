import
  unicode,
  tables

const
  SPACE = " ".runeAt(0)
  NL = "\n".runeAt(0)
  DOUBLE_QUOTE = "\"".runeAt(0)
  CURLY_START = "{".runeAt(0)
  CURLY_STOP = "}".runeAt(0)
  EQUAL = "=".runeAt(0)
  NULL = "?".runeAt(0)
  NONE = "_".runeAt(0)
  SLASH = "\\".runeAt(0)
  MULTILINE_START = "<".runeAt(0)
  MULTILINE_STOP = ">".runeAt(0)

  allPunctuation = [CURLY_START, CURLY_STOP, EQUAL, NULL, NONE, MULTILINE_START, MULTILINE_STOP]

  
const
  ESCSEQ = {
    "\\t": "\t".runeAt(0),  # tab
    "\\n": "\n".runeAt(0),  # new line
    "\\v": "\v".runeAt(0),  # vertical tab
    "\\f": "\f".runeAt(0),  # form feed
    "\\r": "\r".runeAt(0),  # carriage return; commonly inserted in Windows environments
    "\\e": "\e".runeAt(0),  # escape
    "\\\"": "\"".runeAt(0), # double quote
    "\\\\": "\\".runeAt(0), # backslash
  }.toTable

type
  runeType = enum
    runeSpace,
    runeNewLine,
    runeQuote,
    runePunctuation,
    runeSlash,
    runeAlpha
  TokenKind* = enum
    tkDocStart
    tkIndent,
    tkString,
    tkPunctuation,
    tkSpace
  Token* = object
    row: int
    col: int
    case kind*: TokenKind
    of tkDocStart:
      discard
    of tkIndent:
      indentLevel*: int
    of tkString:
      content*: string
      atEnd: bool
    of tkPunctuation:
      identifier*: string
    of tkSpace:
      discard

type
  LexerDetail = object
    row: int
    column: int
    token: Token
    ready: Token
    done: bool
    slashFlag: bool


proc interpretRune(r: Rune): runeType =
  if r == SPACE:
    result = runeSpace
  elif r == DOUBLE_QUOTE:
    result = runeQuote
  elif r == NL:
    result = runeNewLine
  elif allPunctuation.contains(r):
    result = runePunctuation
  else:
    result = runeAlpha


proc handleSlash(lex: var LexerDetail, r: Rune): Rune =
  if lex.slashFlag:
    let possibleSeq = "\\" & $r
    if ESCSEQ.contains(possibleSeq):
      result = ESCSEQ[possibleSeq]
    else:
      lex.token.content.add SLASH
      result = r
    lex.slashFlag = false
  else:
    result = r


proc scanRune*(lex: var LexerDetail, r: Rune) =
  var nextState = lex.token.kind
  lex.column += 1
  #
  # decide with next rune
  #
  var runeType = interpretRune(r)
  case lex.token.kind:
  of tkDocStart:
    case runeType:
    of runeSpace:
      echo "tkds ERROR space found at start of document"
    of runeQuote:
      nextState = tkString
    of runePunctuation:
      nextState = tkPunctuation
    else:
      echo "tkds ERROR on " & $r
  of tkIndent:
    case runeType:
    of runeSpace:
      lex.token.indentLevel += 1
    of runeQuote:
      nextState = tkString
    of runePunctuation:
      nextState = tkPunctuation
    else:
      echo "tki ERROR on " & $r
  of tkString:
    case runeType:
    of runeQuote:
      if lex.slashFlag:
        lex.token.content.add lex.handleSlash(r)
      else:
        lex.token.atEnd = true
    of runeSpace:
      if lex.token.atEnd:
        nextState = tkSpace
      else:
        lex.token.content.add lex.handleSlash(r)
    of runeNewLine:
      if lex.slashFlag:
        lex.token.content.add lex.handleSlash(r)
      else:
        if not lex.token.atEnd:
          echo "tks ERROR - NL found in middle of string"
        nextState = tkIndent
    else:
      if lex.token.atEnd:
        echo "tks ERROR something found after the closing quote"
      else:
        if lex.slashFlag:
          lex.token.content.add lex.handleSlash(r)
        else:
          if r == SLASH:
            lex.slashFlag = true
          else:
            lex.token.content.add r
  of tkSpace:
    case runeType:
    of runeSpace:
      discard
      # echo "tks ERROR - skipping multiple spaces"
    of runeQuote:
      nextState = tkString
    of runePunctuation:
      nextState = tkPunctuation
    of runeNewLine:
      nextState = tkIndent
      # echo "tks ERROR - space found at end of line"
    else:
      echo "tks ERROR on " & $r
  of tkPunctuation:
    case runeType:
    of runePunctuation:
      lex.token.identifier.add r
    of runeSpace:
      nextState = tkSpace
    of runeNewLine:
      nextState = tkIndent
    else:
      echo "tkp ERROR on " & $r
  #
  # if changing state, save work and start token
  #
  if nextState != lex.token.kind:
    if lex.token.kind != tkDocStart:
      lex.ready = lex.token
      lex.done = true
    #
    case nextState:
    of tkDocStart:
      echo "internal error tkds99"
    of tkIndent:
      lex.row += 1
      lex.column = 0
      lex.token = Token(row: lex.row, col: 1, kind: tkIndent, indentLevel: 0)
    of tkString:
      lex.slashFlag = false
      lex.token = Token(row: lex.row, col: lex.column, kind: tkString, content: "", atEnd: false)
    of tkSpace:
      lex.token = Token(row: lex.row, col: lex.column, kind: tkSpace)
    of tkPunctuation:
      lex.token = Token(row: lex.row, col: lex.column, kind: tkPunctuation, identifier: $r)


proc popToken*(lex: var LexerDetail): Token =
  result = lex.ready
  lex.done = false


proc isTokenReady*(lex: LexerDetail): bool =
  result = lex.done


proc newLexer*(): LexerDetail =
  result = LexerDetail()
  result.row = 1
  result.column = 0
  result.token = Token(row: 1, col: 1, kind: tkDocStart)
  result.done = false
  result.slashFlag = false

