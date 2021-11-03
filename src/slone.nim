## This library serializes and deserializes items to the SLONE formatting
## specification.
##
## SLONE stands for Serialized Lists [of] Ordered Named Elements.
##
## This library uses the LONE collection datatype, which is a generic
## List of Ordered Named Elements.
##
## In the Nim language's library, two persistent constants are introduced, 
## ``slnNone`` and ``slnNull``.
##
## .. code:: nim
##
##     # test.nim
##     #
##     # same 
##     import slone
##     
##     var x = newSlone()
##     
##     # none and empty are valid names (keys), but null is not allowed
##     #
##     # So, for a name, None == none
##     #
##     x[""] = slnFromList(@["x", "y", "z"])      # empty
##     x[slnNone] = slnFromList(@["x", "y", "z"]) # none
##     #
##     assert x[""].len == 3
##     assert x[""][slnNone, 0] == "x"
##     assert x[slnNone].len == 3
##     assert x[slnNone][slnNone, 0] == "x"
##     #
##     # "a" is an empty list, "b" is none (it does not exist), "c" is an unknown list
##     # "d" is also unknown but different than "c"
##     #
##     x["a"] = newSlone()     # empty
##     x["b"] = slnNone        # none (could also be performed by ommission)
##     x["c"] = slnNull        # null
##     x["d"] = slnNull        # null
##     #
##     assert x["a"].len == 0
##     assert x["b"] == slnNone
##     assert x["missing key"] == slnNone  # any missing entry returns slnNone
##     assert x["b"] == x["missing key"]   # philisophically, two things that do not exist both don't exist
##     assert x["c"] == slnNull
##     assert x["d"] == slnNull
##     assert x["c"] != x["d"]             # you cannot assume two unknowns are the same.
##    
##     # repetition/order handling
##     #
##     var y = newSlone()
##     y["addr"] = "Unit A"              # new string at ("addr", 0), pos == 0
##     y.add("addr", "1234 Main St")     # new string at ("addr", 1), pos == 1
##     y["phone"] = "5551212"            # new string at ("phone", 0), pos == 2
##     y["phone"] = "5558888"            # replaced string ("phone", 0), pos == 2
##     y.add("addr", "City, State")      # new string at ("addr", 2), pos == 2 and ("phone", 0) moved to pos==3
##
##     assert y["addr"] == "Unit A"
##     assert y["addr", 0] == "Unit A"
##     assert y["addr", 1] == "1234 Main St"
##     assert y["addr", 2] == "City, State"
##     assert y["phone"] == "5558888"
##     assert y["phone", 1] == slnNone
##     
##     assert y.pos("addr", 0) == 0
##     assert y.pos("addr", 1) == 1
##     assert y.pos("addr", 2) == 2
##     assert y.pos("phone") == 3
##     assert y.pos("phone", 0) == 3
##
## Nim's library also supports a SLONE-based schema document.
##
## For each entry (or subdocument entry), the **name** is used for the data
## document's corresponding entry names. The **type** is the expected
## corresponding data type and encoded quantity and nullability. The **value**
## is an empty string unless a subdocument.
##
## Valid Types
##
## string - A sequence of varied-length unicode code points.
##
## ascii - A 7-bit byte sequence conforming to ASCII specification.
##
## int8 - a signed 8-bit integer
##
## int16 - a signed 16-bit integer
##
## int32 - a signed 32-bit integer
##
## int64 - a signed 64-bit integer
##
## uint8 - a unsigned 8-bit integer
##
## uint16 - a unsigned 16-bit integer
##
## uint32 - a unsigned 32-bit integer
##
## uint64 - a unsigned 64-bit integer
##
## float32 - a signed 32-bit floating point number (binary)
##
## float64 - a signed 64-bit floating point number (binary)
##
## bool - A string with either "true" or "false" as the answer.
##
## array - A sequence of unnamed entries of the SAME type.
##
## list - A sequence of unnamed entries of varied types.
##
## map - A sequence of uniquely named entries of the SAME type.
##
## dictionary - A sequence of uniquely named entries of varied types.
##
## lone - A sequence of named entries of varied types.
## 
## An example schema named "person.slone":
##
## .. code:: slone1.0
##
##     #! SLONE 1.0
##     #% schema:person.slone
##     "person_id" : uuid__eq_1 = ""
##     "person_name" : string__eq_1 = ""
##     "address" : array__lte_1 = {
##       _ : string__gte_2 = ""
##     }
##     "age" : int32__lte_1__null = ""
##
## For the above example schema, all of the following are valid documents:
##
## .. code:: slone1.0
##
##     #! SLONE 1.0
##     #% person.slone
##     "person_id" : uuid = "12e38e63-f8ed-43dd-a525-db56a09b37cb"
##     "person_name" : string = "Joe Smith"
##     "address" : array = {
##       _ : string = "123 Main St"
##       _ : string = "Anytown, ST 12345"
##     }
##     "age" : int32) ?
##
## .. code:: slone1.0
##
##     #! SLONE 1.0
##     #% person.slone
##     "person_id" : uuid = "ba3a0310-dd3c-4cce-b9d6-da92d2b48f6b"
##     "person_name" : string = "Mary Doe"
##     "address" : array = {
##       _ : string = "Unit B"
##       _ : string = "Floor 32"
##       _ : string = "3434 Uptown Ave"
##       _ : string = "New York, NY"
##     }
##
## .. code:: slone1.0
##
##     #! SLONE 1.0
##     #% person.slone
##     "person_id" : uuid = "07d58ec6-1e44-4a57-839a-f01c5e20913c"
##     "person_name" : string = "John Dine"
##     "age" : int32 = "62"
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
##     var doc = newSlone(1.0, schemaFile="person.slone")
##     doc["person_id"] = id                             # "uuid" is default for UUID (from slone/uuids lib)
##     doc["person_name"] = "Joe Smith"                  # "string" is default type for a string
##     doc["age"] = age                                  # "int32" is default type for an Option[int32]
##     doc["address"] = newSlone(slnType="array")
##     doc["address"].add "123 Main St"
##     doc["address"].add "Anytown, ST 12345"
##
##     echo $doc                                         # re-ordered per schema
## 

import
  std/options,
  std/strutils

import
  lone

const
  SPACE = " "
  QUOTE = "\""
  EQUALS = "="
  EOL = "\n"
  NULL = "?"
  NOTHING = "_"
  DOC_START = "{"
  DOC_STOP = "}"
  INDENT = "  "
  COLON = ":"


type
  SerializerDetail = object
    indentLevel: int

# TODO: when you get bored, rewrite the serializer to be non-recursive

# fwd ref:
proc serializeLone(detail: var SerializerDetail, doc: Lone): string

proc serializeName(detail: var SerializerDetail, doc: Lone): string =
  if doc.name.isSome:
    result = QUOTE & doc.name.get & QUOTE
  else:
    result = NOTHING

proc serializeValue(detail: var SerializerDetail, doc: Lone): string =
  case doc.kind:
  of LvNull:
    result = NULL
  of LvNothing:
    result = NOTHING
  of LvString:
    result = QUOTE & doc.str & QUOTE
  of LvLone:
    result = DOC_START & EOL
    detail.indentLevel += 1
    result &= serializeLone(detail, doc)
    detail.indentLevel -= 1
    result &= INDENT.repeat(detail.indentLevel)
    result &= DOC_STOP

proc serializeLone(detail: var SerializerDetail, doc: Lone): string =
  for entry in doc:
    # handle indent
    result &= INDENT.repeat(detail.indentLevel)
    # handle name
    result &= serializeName(detail, entry) & SPACE
    # handle type
    if entry.attrType.isSome:
      result &= COLON & SPACE & entry.attrType.get & SPACE
    # handle equals
    result &= EQUALS & SPACE 
    # handle value
    result &= serializeValue(detail, entry) 
    result &= EOL

proc toSlone*(doc: Lone): string =
  result = "#! SLONE 1.0" & EOL
  var detail = SerializerDetail()
  detail.indentLevel = 0
  result &= serializeLone(detail, doc)
