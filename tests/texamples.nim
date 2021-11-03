import unittest

# import
#   unicode
from strutils import repeat, dedent

import lone
import slone

let bigTestString = dedent """
  #! SLONE 1.0
  #% details
  "firstName" : str = "John"
  "lastName" : str = ?
  "age" : int64 = "33"
  "height" : decimal128 = "1.6"
  "mailing address" : passage = {
    _ = "101 Main St"
    _ = "Centerville, IA 32323"
  }
  "firstEmpty" : passage = {
  }
  "almostBinary" : hex = "0123456789ABCDEF"
  "kudoPoints" = {
    _ : decimal128 = "3.2"
    _ : decimal128 = "4.1"
    _ : decimal128 = "1.0"
    _ : decimal128 = ?
    _ : decimal128 = "3.9"
    _ = {
      _ : str = "a"
      _ : str = "b"
    }
  }
  "subscriber_number" : id = "9832"
  "friends" = {
    "best" = {
      "fullName" : str = "Larry \"BigGuy\" Smith"
      "dir" : str = ?
    }
    "next best" = {
      "fullName" : str = "Linda"
      "dir" : str = "C:\\5938\\4"
    }
  }
  "ownType" : color = "blue"
  "small_poem" : poem = "roses are red\nviolets are blue"
  "Fire and Ice by Robert Frost" = |
    "Some say the world will end in fire,\nSome say in ice.\n"
    "From what I’ve tasted of desire\nI hold with those who favor fire.\n"
    "But if it had to perish twice,\nI think I know enough of hate\n"
    "To say that for destruction ice\nIs also great\nAnd would suffice."
  |
"""

let personExample = dedent """
  #! SLONE 1.0
  #% local.personSchema
  "name" = "John Doe"
  "personal number" = "+15555551234"
  "age" = "33"
  "height" = "1.6"
  "mailing_address" = {
    "street" = {
      _ = "1234 Main St."
    }
    "city" = "Springfield"
    "state" = "IL"
    "zip" = "55555"
  }
"""

let personSchema = dedent """
  #! SLONE 1.0
  "header" = {
    "title" = "local.personSchema"
  }
  "types" = {
    "human_name" : string = {
      "min_len" = "1"
      "max_len" = "128"
    }
    "phone_number" : string = {
    }
    "years" : integer = {
      "minimum_number" = "0"
      "maximum_number" = "120"    
    }
    "meters" : integer = {    
      "minimum_number" = "0"
    }
    "address" : object = {
      "fields" = {
        "street": object = {
        }
        "city": string = {
        }
        "state_province": string = {
        }
        "zip": string = {
        }
      }
    }
  }
  "fields" = {
    "name": human_name = {
      "required" = "true"
    }
    "person number" : phone_number = {
    }
    "age": years = {
    }
    "height": meters = {
      "maximum_number" = "3.0"
    }
    "mailing_address" : address = {
      "fields" = {
        "street" : street_text = {
          "fields" = {
            _ : string = {
              "min_entries" = "1"
              "max_entries" = "6"
            }
          }
        }
        "city" = {
        }
        "state" : state_province = {
        }
        "zip" : postal_code = {
          "required" = "true"
          "min_len" = "5"
          "max_len" = "10"
        }      
      }
    }
  }
"""

# suite "Deserialize (no schema)":
#   test "deserialize string to lone object":
#     let result = bigTestString.deserializeToLone()

#     check result["mailing address"][(nothing, 0)].getString == "101 Main St"
#     check result["mailing address"][(nothing, 0)].getType == nothing
#     check result["mailing address"][(nothing, 1)].getString == "Centerville, IA 32323"
#     check result["mailing address"][(nothing, 1)].getType == nothing
#     check result["mailing address"][0].getString == "101 Main St"
#     check result["mailing address"][0].getType == nothing
#     check result["mailing address"][1].getString == "Centerville, IA 32323"
#     check result["mailing address"][1].getType == nothing
#     check result["mailing address"].getListOf(nothing)[0].getString == "101 Main St"
#     check result["mailing address"].getListOf(nothing)[0].getType == nothing
#     check result["mailing address"].getListOf(nothing)[1].getString == "Centerville, IA 32323"
#     check result["mailing address"].getListOf(nothing)[1].getType == nothing

suite "Serialize (no schema)":
  test "untyped shallow lone object to string":
    # arrange
    var a = newLone()
    a["name"] = "John Doe"
    a["personal number"] = "+15555551234"
    a["age"] = "33"
    # act
    var result = a.toSlone()
    # assert
    check result == dedent """
      #! SLONE 1.0
      "name" = "John Doe"
      "personal number" = "+15555551234"
      "age" = "33"
    """
  test "typed shallow lone object to string":
    # arrange
    var a = newLone()
    a["name"] = ("name", "John Doe")
    a["personal number"] = ("phone", "+15555551234")
    a["age"] = ("years", "33")
    # act
    var result = a.toSlone()
    # assert
    check result == dedent """
      #! SLONE 1.0
      "name" : name = "John Doe"
      "personal number" : phone = "+15555551234"
      "age" : years = "33"
    """
  test "deeper lone object to string done simply":
    # arrange
    var a = newLone()
    a["name"] = ("name", "John Doe")
    a["personal number"] = ("phone", "+15555551234")
    a["age"] = ("years", "33")
    var fruit = newLone()
    fruit["common_name"] = "bananna"
    a["favorite fruit"] = fruit
    # a["favorite fruit"] = newLone()
    # a["favorite fruit"]["common_name"] = "bananna"
    var friend = newLone()
    friend["name"] = ("name", "Larry Smith")
    a["friend"] = ("person", friend)
    # a["friend"] = ("person", newLone())
    # a["friend"]["name"] = ("name", "Larry Smith")
    # act
    var result = a.toSlone()
    # assert
    check result == dedent """
      #! SLONE 1.0
      "name" : name = "John Doe"
      "personal number" : phone = "+15555551234"
      "age" : years = "33"
      "favorite fruit" = {
        "common_name" = "bananna"
      }
      "friend" : person = {
        "name" : name = "Larry Smith"
      }
    """
  test "deeper lone object to string with compound brackets":
    # arrange
    var a = newLone()
    a["name"] = ("name", "John Doe")
    a["personal number"] = ("phone", "+15555551234")
    a["age"] = ("years", "33")
    a["favorite fruit"] = newLone()
    a["favorite fruit"]["common_name"] = "bananna"
    a["friend"] = ("person", newLone())
    a["friend"]["name"] = ("name", "Larry Smith")
    # act
    var result = a.toSlone()
    # assert
    check result == dedent """
      #! SLONE 1.0
      "name" : name = "John Doe"
      "personal number" : phone = "+15555551234"
      "age" : years = "33"
      "favorite fruit" = {
        "common_name" = "bananna"
      }
      "friend" : person = {
        "name" : name = "Larry Smith"
      }
    """
