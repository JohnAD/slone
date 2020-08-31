import unittest

import
  json,
  unicode
from strutils import repeat


import slone

const MAX_STRING_LEN = 128

let bigTestString = """
#! SLONE 1.0
"firstName" = "John"
"lastName" = "Doe"
"age" = "33"
"mailing address" = <<
  "101 Main St"
  "Centerville, IA 32323"
>>
"packing address" = <<<
  "101 Main St\n"
  "Centerville, IA 32323"
>>>
"firstEmpty" = <<
>>
"almostBinary" = <<<
  "01234567"
  "89ABCDEF"
>>>
"kudoPoints" = {{
  "3.2"
  "4.1"
  "1.0"
  ?
  "3.9"
  {{
    "a"
    "b"
  }}
}}
"fundHistory" = {{
}}
"randomDetails" = {
}
"subscriber_number" = "9832"
"friends" = {
  "best" = {
    "fullName" = "Larry \"BigGuy\" Smith"
    "dir" = ?
  }
  "next best" = {
    "fullName" = "Linda"
    "dir" = "C:\\5938\\4"
  }
}
"""

let expectedJsonPretty = """{
  "firstName": "John",
  "lastName": "Doe",
  "age": "33",
  "mailing address": "101 Main St\nCenterville, IA 32323",
  "packing address": "101 Main St\nCenterville, IA 32323",
  "firstEmpty": "",
  "almostBinary": "0123456789ABCDEF",
  "kudoPoints": [
    "3.2",
    "4.1",
    "1.0",
    null,
    "3.9",
    [
      "a",
      "b"
    ]
  ],
  "fundHistory": [],
  "randomDetails": {},
  "subscriber_number": "9832",
  "friends": {
    "best": {
      "fullName": "Larry \"BigGuy\" Smith",
      "dir": null
    },
    "next best": {
      "fullName": "Linda",
      "dir": "C:\\5938\\4"
    }
  }
}"""

let trimmedTestString = bigTestString.strip() & "\n"

var testJson = %*{
  "firstName": "John",
  "lastName": "Doe",
  "age": "33",
  "mailing address": "101 Main St\nCenterville, IA 32323",
  "control address": "101 Main St\nCenterville, IA\t32323",
  "firstEmpty": "",
  "kudoPoints": [
    "3.2",
    "4.1",
    "1.0",
    newJNull(),
    "3.9",
    [
      "a",
      "b"
    ]
  ],
  "fundHistory": [],
  "randomDetails": {},
  "subscriber_number": "9832",
  "friends": {
    "best": {
      "fullName": "Larry \"BigGuy\" Smith",
      "dir": newJNull()
    },
    "next best": {
      "fullName": "Linda",
      "dir": "C:\\5938\\4"
    }
  }
}
testJson["packed string"] = newJString("0123456789\t".repeat(30))
testJson["127onFirstLine"] = newJString("a".repeat(MAX_STRING_LEN - 1) & "\t" & "b".repeat(200))
testJson["canStillUsePassage"] = newJstring("p".repeat(MAX_STRING_LEN) & "\nline two")
testJson["tooLongToPassage"] = newJstring("p".repeat(MAX_STRING_LEN + 1) & "\nline two")

let rawExpectedSloneString = """
#! SLONE 1.0
"firstName" = "John"
"lastName" = "Doe"
"age" = "33"
"mailing address" = <<
  "101 Main St"
  "Centerville, IA 32323"
>>
"control address" = "101 Main St\nCenterville, IA\t32323"
"firstEmpty" = ""
"kudoPoints" = {{
  "3.2"
  "4.1"
  "1.0"
  ?
  "3.9"
  {{
    "a"
    "b"
  }}
}}
"fundHistory" = {{
}}
"randomDetails" = {
}
"subscriber_number" = "9832"
"friends" = {
  "best" = {
    "fullName" = "Larry \"BigGuy\" Smith"
    "dir" = ?
  }
  "next best" = {
    "fullName" = "Linda"
    "dir" = "C:\\5938\\4"
  }
}
"packed string" = <<<
  "0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t01234567"
  "89\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123"
  "456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t0123456789\t"
>>>
"127onFirstLine" = <<<
  "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  "\tbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
>>>
"canStillUsePassage" = <<
  "pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp"
  "line two"
>>
"tooLongToPassage" = <<<
  "pppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp"
  "p\nline two"
>>>
"""
let expectedSloneString = rawExpectedSloneString.strip() & "\n"


suite "Example SLONE From Documentation":
  test "deserialize string to json":
    let j = readSloneIntoJson(trimmedTestString)

    check j.pretty() == expectedJsonPretty

    check j["mailing address"].getStr == j["packing address"].getStr
  test "serialize json to string":
    let s = testJson.toSloneString()

    check s == expectedSloneString
