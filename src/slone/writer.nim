import
  json,
  unicode,
  tables

from strutils import repeat

type
  StringMethod = enum
    smStraight,
    smPassage,
    smPacked

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
  SPACE = " "
  NL = "\n"
  NL_CHAR = char(10)
  NL_RUNE = "\n".runeAt(0)
  DOUBLE_QUOTE = "\""
  TAB = "  "

  MAX_STRING_LEN = 128 # length measured in unicode characters, NOT bytes

  ESCSEQ = {
    '\t': "\\t",  # tab
    '\n': "\\n",  # new line
    '\v': "\\v",  # vertical tab
    '\f': "\\f",  # form feed
    '\r': "\\r",  # carriage return; commonly inserted in Windows environments
    '\e': "\\e",  # escape
    '\"': "\\\"", # double quote
    '\\': "\\\\", # backslash
  }.toTable

  CONTROL_CHARS = [
    '\t',  # tab
    '\v',  # vertical tab
    '\f',  # form feed
    '\r',  # carriage return; commonly inserted in Windows environments
    '\e',  # escape
  ]


proc escapeOne(ch: char): string =
  if ESCSEQ.contains(ch):
    result &= ESCSEQ[ch]
  else:
    result.add ch


proc escapeOne(r: Rune): seq[Rune] =
  if size(r) == 1:
    result = escapeOne(($r)[0]).toRunes
  else:
    result = @[r]


proc escaped(s: string): string =
  result = ""
  for ch in s:
    result &= escapeOne(ch)


proc containsControlCharacter(s: string): bool =
  # does it contain escaped characters, but not counting NL, quotes, and backslash
  result = false
  for cc in CONTROL_CHARS:
    if s.contains(cc):
      result = true
      return


proc containsNewLine(s: string): bool =
  result = s.contains(NL_CHAR)


proc quote(s: string): string =
  result = DOUBLE_QUOTE & escaped(s) & DOUBLE_QUOTE


iterator nextEighty(rawString: string): string =
  # interates through the string 128 runes at a time (after escapement)
  # because you can't "split" an escape sequence, it is possible for
  # some sequences to be 127 runes rather than 128.
  var subString: seq[Rune] = @[]
  var subLen = 0
  for r in runes(rawString):
    let nextSeq = escapeOne(r)
    if (nextSeq.len + subLen) <= MAX_STRING_LEN:
      subString &= nextSeq
    else:
      yield DOUBLE_QUOTE & $subString & DOUBLE_QUOTE
      subString = nextSeq
    subLen = subString.len
  if subString.len > 0:
    yield DOUBLE_QUOTE & $subString & DOUBLE_QUOTE


proc tab(level: int): string =
  result = TAB.repeat(level)


proc decideStringMethod(rawString: string): StringMethod =
  result = smStraight
  if containsControlCharacter(rawString):
    let escapedString = escaped(rawString)
    if len(escapedString) > MAX_STRING_LEN:
      result = smPacked
    else:
      result = smStraight
  else:
    if containsNewLine(rawString):
      result = smPassage
      for subString in split(rawString, NL_RUNE):
        if len(escaped(subString)) > MAX_STRING_LEN:
          result = smPacked
          return
    else:
      let escapedString = escaped(rawString)
      if len(escapedString) > MAX_STRING_LEN:
        result = smPacked
      else:
        result = smStraight


proc serialize(j: JsonNode, indent: int): string  # forward ref


proc serializeObjectItems(j: JsonNode, indent: int): string =
  result = ""
  for key in j.keys():
    result &= tab(indent)
    result &= quote(key)
    result &= SPACE
    result &= ASSIGNMENT
    result &= SPACE
    result &= serialize(j[key], indent)


proc serializeObject(j: JsonNode, indent: int): string =
  result = OBJECT_START & NL
  let newIndent = indent + 1
  result &= serializeObjectItems(j, newIndent)
  result &= tab(indent) & OBJECT_END & NL


proc serializeArrayItems(j: JsonNode, indent: int): string =
  result = ""
  for item in j.items():
    result &= tab(indent)
    result &= serialize(item, indent)


proc serializeArray(j: JsonNode, indent: int): string =
  result = LIST_START & NL
  let newIndent = indent + 1
  result &= serializeArrayItems(j, newIndent)
  result &= tab(indent) & LIST_END & NL


proc serializePassageString(j: JsonNode, indent: int): string =
  result = PASSAGE_START & NL
  for subString in split(j.getStr(), NL_RUNE):
    result &= tab(indent + 1) & quote(subString) & NL
  result &= tab(indent) & PASSAGE_END & NL


proc serializePackedString(j: JsonNode, indent: int): string =
  result = PACKED_START & NL
  for subString in nextEighty(j.getStr()):
    result &= tab(indent + 1) & subString & NL
  result &= tab(indent) & PACKED_END & NL


proc serializeString(j: JsonNode, indent: int): string =
  let serMethod = decideStringMethod(j.getStr)
  case serMethod
  of smStraight:
    result = quote(j.getStr)
    result &= NL
  of smPassage:
    result = serializePassageString(j, indent)
  of smPacked:
    result = serializePackedString(j, indent)


proc serializeNull(j: JsonNode, indent: int): string =
  result = UNKNOWN & NL


proc serialize(j: JsonNode, indent: int): string =
  result = ""
  case j.kind
  of JObject:
    result = serializeObject(j, indent)
  of JArray:
    result = serializeArray(j, indent)
  of JString:
    result = serializeString(j, indent)
  of JNull:
    result = serializeNull(j, indent)
  else:
    echo "not done with lib"


proc toSloneString*(j: JsonNode): string =
  result = "#! SLONE 1.0\n"
  result &= serializeObjectItems(j, 0)

