## This library serializes and deserializes items to the SLONE formatting
## specification.
##
## SLONE stands for Serialized Lists [of] Ordered Named Elements.
##
## For the current version, SLONE is converted to/from JSON documents.
##
## Additional libraries will also eventually support other Nim objects, arrays,
## and other standard library types.
##
## This library is limited to serialization and deserialization of the core
## components and does not implement any "schema". Such support would come
## from other libraries.
##
## = The SLONE Specication
## 
## The role of SLONE is to enable a text-based data format for machine to 
## machine communication and storage that is also human readable and trackable
## by line-oriented systems such as `diff` and `git`.
##
## If you are wanting machine-to-machine storage/communication that is not
## trackable by line-oriented systems, I recommend using JSON rather than SLONE
## as JSON is almost universally supported.
##
## If you are wanting human-to-machine storage/communication, such as a config
## file, I recommend using YAML rather than SLONE. YAML is also mostly 
## line-oriented and has more universal support. More importantly, YAML is
## also forgiving whereas SLONE is **very** strict.
##
## == Goals
##
## The specific goals of SLONE are:
##
## 1. Changes Easily And Precisely Tracked at the Line Level
##
##    Utility such as DIFF and GIT should be able to pinpoint the differences
##    between two SLONE documents at a line-by-line level.
##    
##    For example, when adding an entry to a list, the new entry is on
##    it's own line (showing an "add") and should not effect any other lines.
##
## 2. Little Presumption Of A System's Unique Types
##
##    SLONE supports the following types:
##
##    * strings
##    * unknowns (aka NULLs)
##    * lists
##    * ordered objects (aka dictionaries)
## 
##    and optionally:
## 
##    * explicit "nothing" indicators
##
##    Very specifically, SLONE does not support numbers, dates, vectors, etc
##    directly.
##
##    Certinaly, one can store numbers, dates, and vectors, but that is
##    intepreted by the calling program or schema library from the strings. The
##    SLONE specification does NOT do that interpretation.
##
## 3. Fast Simple Single-Pass Parsing
##
##    A document should be verifiable and parsed in a single pass with nothing
##    more than, perhaps, a few simple state variable.
##
##    This is one of the reasons that the format is so strict. Keep in mind
##    that the spec is designed to be human readable; it not meant to be edited
##    or written by humans.
##
## 4. Idempontency (Absolutely Consistent Replication)
##
##    If a SLONE data store is read by a library and then output to another
##    data store, the content of the new data store should be absolutely 
##    identical to the original.
##
##    Put another way: if a program reads a file encoded in SLONE (without a
##    schema) into a variable, and then it serializes that variable into
##    a new file, then the MD5 checksum and length of both files should be
##    exactly identical.
##
##    There is only one way to write a SLONE document for any particular
##    collection of data.
##
## And, to emphasize the role of the SLONE specification:
##
## 5. Human Readable, but NOT Human Writable
##
##    While a person could write a SLONE document by hand, doing such edits
##    by hand is NOT a goal and is generally frustrating. Other specifications
##    such as JSON or YAML are much better suited to this due to their flexibility.
##
## == Details
##
## Data is stored in lines of text. The text is in UTF8 format. All UTF8 text
## should be normalized and composed (NFC).
##
## Each line is
## terminated by a single NewLine (\n) character. While there is no formal line
## length limit, the length is self-limiting due to other restrictions.
##
## The very first line of the datastore is a descriptor that is not part of the
## data. The descriptor is ``#! SLONE 1.0``, exactly, followed by a NewLine. A datastore
## missing this line is in error. The spacing and capitalization is not optional.
##
## For this specification, a "character" is a UTF-8 code point. So, character
## can be 1, 2, or 4 bytes long; depending on the language code page. See published
## UTF-8 specification for details.
##
## After the indentation, each element is separated by exacly one space. If an
## element starts with a double-quote symbol, then that element is ended by the
## next unescaped quote.
##
## The following are allowed elements:
## 
##    {    start of list; must be followed by NL
##    }    end of list; must be followed by NL
##    {{   start of ordered dictionary; must be followed by NL
##    }}   end of ordered dictionary; must be followed by NL
##    "    start and end of quoted name or value element
##    =    assignment of following element/value to name
##    ?    unknown/null
##    _    not-applicable or never existant; yes, this is VERY different than null or empty
##    <<<  packed string (packed interpretation)
##    >>>  end of packed string
##    <<   passage string (implied NewLines)
##    >>   end of passage string
##
## A name string is always stored in double quotes and escaped as needed.
##
## A name, including quotes and need escapes, must be less than 128 characters
## in length. An empty string is permissible.
##
## The choice of serializing a value string is not arbitrary. All value strings
## are surrounded by double quotes regardless of method. In the following algorithm,
## when "length" is refererred to, it includes any needed
## escaping.
##
## 1. If the string:
##    * contains one or more NewLines but no control characters, and
##    * when split by newlines into substrings, none of those substrings
##      are longer than 128 characters, then
##    the passage method "<< >>" is used. Empty substring lines are
##    allowed and represented by a pair of quotes.
##    For this calculation, since the NewLines are implied by the passage method,
##    they are not included in the substring line lengths.
##
## 2. If the string length is 128 characters or less, it is fit onto a single line.
##
## 3. Otherwise the packed string "<<< >>>" method is used.
##
## The datastore ends with NewLine on the last line. There are never any
## empty lines in the datastore.
##
## How a string or substring is encoded:
##   * start with a double-quote symbol (")
##   * continue with each unicode character in the string, but insert the
##     substitutions found in the "String Escape Sequence Table":
##   * ends with an unescaped double-quote symbol (")
##
## == String Escape Sequence Table
##
## When reading (de-serializing) SLONE strings, the following two-character
## sequences are interpreted as follows codes/characters.
##
## ========  =======  ===  ================
## sequence  decimal  hex  descrption
## ========  =======  ===  ================
## \t        9        09   tab (horizontal)
## \n        10       0A   new line
## \v        11       0B   vertical tab
## \f        12       0C   form feed
## \r        13       0D   carriage return
## \e        27       1B   escape
## \"        34       22   double quote
## \\        92       5D   slash
## 
## When writing a SLONE document (serializing), the reverse interpretation must
## occur.
##
## == Sample
##
## ```
## "firstName" = "John"
## "lastName" = "Doe"
## "age" = "33"
## "mailing address" = <<
##   "101 Main St"
##   "Centerville, IA 32323"
## >>
## "subscriber_number" = "9832"
## "kudoPoints" = {
##   "3.2"
##   "4.1"
##   "1.0"
##   ?
##   "3.9"
## }
## "fundHistory" = {
## }
## "friends" = {{
##   "best" = {
##     "fullName" = "Larry Smith"
##     "acctID" = "3323"
##   }
##   "next best" = {
##     "fullName" = "Linda"
##     "acctId" = "5938"
##   }
## }}
##
## ```


import
  json

# import
#   serialization

import
#  slone/[reader, writer, types]
  slone/[reader, writer]


export
  json,
  # serialization,
  reader,
  writer


# serializationFormat OddlyStrictYaml,
#   Reader = OddlyStrictYamlReader,
#   Writer = OddlyStrictYamlWriter,
#   PreferedOutput = string,
#   mimeType = "application/x-osyaml"


