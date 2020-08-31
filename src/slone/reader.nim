import
  json,
  unicode

import lexer

type
  ParserState = enum
    psStart,
    psObjectEqual,
    psObjectValue,
    psIndent
  Mode = enum
    mdObject,
    mdPassage,
    mdPacked,
    mdList
  Parser = object
    doc: JsonNode
    state: ParserState
    mode: Mode
    path: array[100, JsonNode]  # this library is limited to 100 levels of depth
    indent: array[100, int]     # the corresponding indents
    pathIndex: int
    currentName: string
    longString: string

const
  ASSIGNMENT = "="
  PASSAGE_START = "<<"
  PASSAGE_END = ">>"
  PACKED_START = "<<<"
  PACKED_END = ">>>"
  OBJECT_START = "{"
  OBJECT_END = "}"
  LIST_START = "{{"
  LIST_END = "}}"
  UNKNOWN = "?"



proc current(parser: Parser): JsonNode =
  result = parser.path[parser.pathIndex]


proc assignAsObject(parser: var Parser) =
  parser.path[parser.pathIndex] = newJObject()


proc addObject(parser: var Parser, name: string) =
  var temp = newJObject()
  parser.current()[name] = temp
  parser.pathIndex += 1
  parser.path[parser.pathIndex] = temp


proc addList(parser: var Parser, name: string) =
  var temp = newJArray()
  case parser.current().kind
  of JObject:
    parser.current()[name] = temp
  of JArray:
    parser.current().add temp
  else:
    echo "ERR addList " & $parser.current().kind
  parser.pathIndex += 1
  parser.path[parser.pathIndex] = temp


proc finishObject(parser: var Parser) =
  parser.pathIndex -= 1


proc finishList(parser: var Parser) =
  parser.pathIndex -= 1


proc restoreMode(parser: var Parser) =
  case parser.current().kind
  of JObject:
    parser.mode = mdObject
  of JArray:
    parser.mode = mdList
  else:
    echo "ERR restoreMode " & $parser.current().kind

proc addString(parser: var Parser, name: string, value: string) =
  # add string to object
  parser.current()[name] = newJString(value)


proc addString(parser: var Parser, item: string) =
  # add string to list
  parser.current().add newJString(item)


proc addUnknown(parser: var Parser, name: string) =
  parser.current()[name] = newJNull()


proc addUnknown(parser: var Parser) =
  parser.current().add newJNull()


proc newParser(): Parser =
  result.state = psStart
  result.mode = mdObject
  result.pathIndex = 0
  result.assignAsObject()


proc getJson(parser: Parser): JsonNode =
  result = parser.path[0]


proc parseToken(parser: var Parser, token: Token) =
  var nextState = parser.state
  case parser.state:
  of psStart:
    case token.kind:
    of tkString:
      case parser.mode
      of mdObject:
        parser.currentName = token.content
        nextState = psObjectEqual
      of mdPassage:
        if len(parser.longString) > 0:
          parser.longString = parser.longString & "\n"
        parser.longString = parser.longString & token.content
        nextState = psIndent
      of mdPacked:
        parser.longString = parser.longString & token.content
        nextState = psIndent
      of mdList:
        parser.addString(token.content)
        nextState = psIndent
    of tkPunctuation:
      case parser.mode
      of mdObject:
        case token.identifier
        of OBJECT_END:
          parser.finishObject()
          parser.restoreMode()
          nextState = psIndent
        of UNKNOWN:
          echo "pss ERR an unknown (?) aka null cannot be used as a name"
        else:
          echo "pss ERR unknown punctuation (object context)"
      of mdPassage:
        case token.identifier
        of PASSAGE_END:
          parser.addString(parser.currentName, parser.longString)
          parser.restoreMode()
          nextState = psIndent
        else:
          echo "pss ERR unknown punctuation (passage context)"
      of mdPacked:
        case token.identifier
        of PACKED_END:
          parser.addString(parser.currentName, parser.longString)
          parser.restoreMode()
          nextState = psIndent
        else:
          echo "pss ERR unknown punctuation (packed context)"
      of mdList:
        case token.identifier
        of OBJECT_START:
          parser.addObject(parser.currentName)
          parser.mode = mdObject
          nextState = psIndent
        of LIST_START:
          parser.addList(parser.currentName)
          nextState = psIndent          
        of LIST_END:
          parser.finishList()
          parser.restoreMode()
          nextState = psIndent
        of UNKNOWN:
          parser.addUnknown()
          nextState = psIndent
        else:
          echo "pss ERR unknown punctuation (list context)"
    else:
      echo "pss ERR"
  of psObjectEqual:
    case token.kind:
    of tkPunctuation:
      if token.identifier == ASSIGNMENT:
        nextState = psObjectValue
      else:
        echo "psoe ERR did not find equal sign"
    else:
      echo "psoe ERR"
  of psObjectValue:
    case token.kind:
    of tkString:
      parser.addString(parser.currentName, token.content)
      nextState = psIndent
    of tkPunctuation:
      case token.identifier:
      of OBJECT_START:
        parser.addObject(parser.currentName)
        nextState = psIndent
      of PASSAGE_START:
        parser.mode = mdPassage
        parser.longString = ""
        nextState = psIndent
      of PACKED_START:
        parser.mode = mdPacked
        parser.longString = ""
        nextState = psIndent
      of LIST_START:
        parser.mode = mdList
        parser.addList(parser.currentName)
        nextState = psIndent
      of UNKNOWN:
        parser.addUnknown(parser.currentName)
        nextState = psIndent
      else:
        echo "psov ERR (bad punctuation)"
    else:
      echo "psov ERR"
  of psIndent:
    case token.kind:
    of tkIndent:
      nextState = psStart
    else:
      echo "psnl ERR"

  if nextState != parser.state:
    parser.state = nextState


proc readSloneIntoJson*(str: string): JsonNode =
  var parser = newParser()
  var lex = newLexer()
  const expectedSheBang = "#! SLONE 1.0\n"
  const sheBangLen = expectedSheBang.len

  if str[0 ..< sheBangLen] != expectedSheBang:
    echo "BAD SHEBANG"

  for r in str[sheBangLen ..< str.len].runes:
    # echo "> " & $r
    lex.scanRune(r)
    if lex.isTokenReady:
      let nextToken = lex.popToken()
      if nextToken.kind != tkSpace:
        # echo "TOKEN: " & $nextToken
        parser.parseToken(nextToken)
  result = parser.getJson()

