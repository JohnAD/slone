## This library serializes and deserializes items to the SLONE formatting
## specification.
##
## SLONE stands for Serialized Lists [of] Ordered Named Elements.
##
## This library uses the LONE collection datatype, which is a generic
## List of Ordered Named Elements.
##
## In the Nim language's library, two persistent constants are introduced, 
## ``nothing`` and ``null``.
## 
## An example schema named "person.slone":
##
## .. code:: slone1.0
##
##     #! SLONE 1.0
##     _ : field = {
##       "name" : name = "person_id"
##       "type" : type = "uuid"
##       "element" : element = "value"
##       "required" : int = "1"
##     }
##     _ : field = {
##       "name" : name = "full name"
##       "type" : type = "name"
##       "element" : element = "value"
##       "required" : int = "1"
##     }
##     _ : field = {
##       "name" : name = "mailing address"
##       "type" : type = "address_label"
##       "element" : element = "list"
##       "children" : children = {
##         _ : field = {
##           "element" : element = "string"
##           "type": type = "line"
##           "required" : int = "2"
##         }
##       }
##     }
##     _ : field = {
##       "name" : name = "age"
##       "type" : type = "uint8"
##       "element" : element = "value"
##     }
##
## For the above example schema, all of the following are valid documents:
##
## .. code:: slone1.0
##
##     #! SLONE 1.0
##     #% person.slone
##     "person_id" : uuid = "12e38e63-f8ed-43dd-a525-db56a09b37cb"
##     "full name" : name = "Joe Smith"
##     "mailing address" : address_label = {
##       _ : line = "123 Main St"
##       _ : line = "Anytown, ST 12345"
##     }
##     "age" : uint8 = ?
##
## .. code:: slone1.0
##
##     #! SLONE 1.0
##     #% person.slone
##     "person_id" : uuid = "ba3a0310-dd3c-4cce-b9d6-da92d2b48f6b"
##     "full name" : name = "Mary Doe"
##     "address" : address_label = {
##       _ : line = "Unit B"
##       _ : line = "Floor 32"
##       _ : line = "3434 Uptown Ave"
##       _ : line = "New York, NY"
##     }
##
## .. code:: slone1.0
##
##     #! SLONE 1.0
##     #% person.slone
##     "person_id" = "07d58ec6-1e44-4a57-839a-f01c5e20913c"
##     "full name" = "John Dine"
##     "age" = "62"
##
## The code used to generate the first document above:
##
## .. code:: nim
## 
##     import slone
##     import slone/uuids
##     
##     var id = genUUID()
##     var age: Option[int32] = null
## 
##     var doc = newLone()
##     doc["person_id"] = id                             # a real UUID is serialized as a string (from slone/uuids lib)
##     doc["full name"] = "Joe Smith"
##     doc["age"] = age
##     doc["mailing address"] = newLone()
##     doc["mailing address"].add(nothing, "123 Main St")
##     doc["mailing address"].add(nothing, "Anytown, ST 12345")
##
##     echo $doc                                                  # serialized but without schema or types
##     echo doc.seriallize(1.0, schemaFile="person.slone")        # serialized and re-ordered per schema; with full type annotations
##     echo doc.serializeUntyped(1.0, schemaFile="person.slone")  # serialized and re-ordered per schema; but with no type annotations 
##
import
  std/options,
  std/strutils,
  std/unicode

import
  lone

const
  INDENT = "  "
  SPACE = ' '
  QUOTE = '\"'
  EQUALS = '='
  EOL = '\n'
  NULL = '?'
  NOTHING = '_'
  DOC_START = '{'
  DOC_STOP = '}'
  COLON = ':'
  BACKSLASH = '\\'
  BAR = '|'
  TAB = '\t'
  VT = '\v'
  FF = '\f'
  CR = '\r'
  ESC = '\e'

type
  SerializerDetail = object
    indentLevel: int
    showTypes: bool

# TODO: when you get bored, rewrite the serializer to be non-recursive

# fwd ref:
proc serializeLone(detail: var SerializerDetail, doc: Lone): string

proc escaped(content: string, start: int, stop: int): string =
  # | \t      | 9       | 09  | tab (horizontal) |
  # | \n      | 10      | 0A  | new line |
  # | \v      | 11      | 0B  | vertical tab |
  # | \f      | 12      | 0C  | form feed |
  # | \r      | 13      | 0D  | carriage return |
  # | \e      | 27      | 1B  | escape |
  # | \"      | 34      | 22  | double quote |
  # | \\      | 92      | 5D  | backslash |
  if start > stop:
    return
  for i in start .. stop:
    let ch = content[i]
    if ch == TAB:
      result &= BACKSLASH & "t"
    elif ch == EOL:
      result &= BACKSLASH & "n"
    elif ch == VT:
      result &= BACKSLASH & "v"
    elif ch == FF:
      result &= BACKSLASH & "f"
    elif ch == CR:
      result &= BACKSLASH & "r"
    elif ch == ESC:
      result &= BACKSLASH & "e"
    elif ch == QUOTE:
      result &= BACKSLASH & QUOTE
    elif ch == BACKSLASH:
      result &= BACKSLASH & BACKSLASH
    else:
      result &= ch
    # TODO: handle general control characters

proc stringify(detail: var SerializerDetail, content: string): string =
  # TODO: make this work with unicode properly
  var remaining = content.len()
  let lastIndex = remaining - 1
  if remaining <= 80:
    result = QUOTE & escaped(content, 0, lastIndex) & QUOTE
  else:
    result = BAR & EOL
    var index = 0
    var nextIndex = 0
    var segment = ""
    while remaining > 0:
      if remaining <= 40:
        segment = escaped(content, index, lastIndex)
        remaining = 0
      else:
        nextIndex = index + 40
        while nextIndex < (index + 80):
          let ch = content[nextIndex]
          if ch == EOL:
            break
          if nextIndex >= lastIndex:
            break
          nextIndex += 1
        segment = escaped(content, index, nextIndex)
        let removed = nextIndex - index
        index += removed
        remaining -= removed
      result &= INDENT.repeat(detail.indentLevel + 1) & QUOTE & segment & QUOTE & EOL
    result &= INDENT.repeat(detail.indentLevel) & BAR

proc serializeName(detail: var SerializerDetail, doc: Lone): string =
  if doc.name.isSome:
    result = stringify(detail, doc.name.get)
  else:
    result = $NOTHING

proc serializeValue(detail: var SerializerDetail, doc: Lone): string =
  case doc.kind:
  of LvNull:
    result = $NULL
  of LvNothing:
    result = $NOTHING
  of LvString:
    result = stringify(detail, doc.str)
  of LvLone:
    result = $DOC_START & $EOL
    detail.indentLevel += 1
    result &= serializeLone(detail, doc)
    detail.indentLevel -= 1
    result &= INDENT.repeat(detail.indentLevel)
    result &= $DOC_STOP

proc serializeLone(detail: var SerializerDetail, doc: Lone): string =
  for entry in doc:
    # handle indent
    result &= INDENT.repeat(detail.indentLevel)
    # handle name
    result &= serializeName(detail, entry) & SPACE
    # handle type
    if detail.showTypes:
      if entry.attrType.isSome:
        result &= $COLON & $SPACE & entry.attrType.get & $SPACE
    # handle equals
    result &= $EQUALS & $SPACE 
    # handle value
    result &= serializeValue(detail, entry) 
    result &= $EOL

proc toSlone*(doc: Lone, types: bool = true): string =
  result = "#! SLONE 1.0" & $EOL
  var detail = SerializerDetail()
  detail.indentLevel = 0
  detail.showTypes = types
  result &= serializeLone(detail, doc)



type
  SerializationState = enum
    ssTabbing,
    ssName,
    ssNameSpace,
    ssType,
    ssTypeSpace,
    ssEquals,
    ssEqualsSpace,
    ssValuePending,
    ssValueString,
    ssValueNull,
    ssEOL,
    ssDoneDueToError

type
  DeserializerObject = object
    doc: string
    docLen: int
    runeIndex: int
    charIndex: int
    lineIndex: int

# fwd ref:
proc parseObject(d: var DeserializerObject): Lone


proc parseSubObject(d: var DeserializerObject): Lone =
  if (d.runeIndex < d.docLen):
    d.charIndex += 1
    d.runeIndex += 1
    let r = d.doc.runeAt(d.runeIndex)
    if $r == $EOL:
      result = parseObject(d)
    else:
      echo "Bad character `" & $r & "` found at line " & $d.lineIndex & " char " & $d.charIndex
  else:
    echo "Object terminated early at line " & $d.lineIndex & " char " & $d.charIndex


proc parseObject(d: var DeserializerObject): Lone =
  template nextLine() =
    d.charIndex = 0
    d.lineIndex += 1
    tabChars = 0
  template doErr() = 
    echo "Bad character `" & $r & "` found at line " & $d.lineIndex & " char " & $d.charIndex
    echo "In state " & $state
    state = ssDoneDueToError
  result = Lone(kind: LvLone)
  var name = some("")
  var valueKind = LvNull
  var valueString = ""
  var state = SerializationState.ssTabbing
  var prefixCtr = 0
  var schema = ""
  var firstQuote = false
  var lastQuote = false
  var tabChars = 0
  #
  while (d.runeIndex < d.docLen):
    d.charIndex += 1
    d.runeIndex += 1
    let r = d.doc.runeAt(d.runeIndex)
    case state:
    of ssTabbing:
      if $r == $QUOTE:
        state = ssName
        name = some("")
      elif $r == $NOTHING:
        state = ssNameSpace
        name = none(string)
      elif $r == $SPACE:
        tabChars += 1
      elif $r == $DOC_STOP:
        break
      else:
        doErr()
    of ssName:
      if $r == $QUOTE:
        state = ssNameSpace
      elif $r == $EOL:
        doErr()
      else:
        name.get &= $r
    of ssNameSpace:
      if $r == $SPACE:
        state = ssEquals
      else:
        doErr()
    of ssType:
      discard # TODO
    of ssTypeSpace:
      discard # TODO
    of ssEquals:
      if $r == $EQUALS:
        state = ssEqualsSpace
      else:
        doErr()
      discard
    of ssEqualsSpace:
      if $r == $SPACE:
        state = ssValuePending
      else:
        doErr()
    of ssValuePending:
      if $r == $QUOTE:
        valueString = ""
        valueKind = LvString
        state = ssValueString
      elif $r == $DOC_START:
        valueKind = LvLone
        result.append(name, parseSubObject(d))
        state = ssEOL
      else:
        doErr() # TODO: support the other kinds of values
    of ssValueString:
      if $r == $QUOTE:
        state = ssEOL
        result.append(name, valueString)
      elif $r == $EOL:
        doErr()
      else:
        valueString &= $r
    of ssValueNull:
      discard
    of ssEOL:
      if $r == $EOL:
        state = ssTabbing  # TODO change to tabbing later
        nextLine()
      else:
        doErr()
    of ssDoneDueToError:
      discard


proc toLone*(doc: string): Lone =
  # TODO: later support schema
  var d = DeserializerObject()
  d.doc = doc
  d.runeIndex = -1 # just before first character at 0
  d.charIndex = 0
  d.lineIndex = 0
  d.docLen = doc.toRunes().len - 1

  d.runeIndex += len("#! SLONE 1.0\n")
  d.lineIndex += 1
  result = parseObject(d)
