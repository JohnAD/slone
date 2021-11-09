Introduction to slone
==============================================================================
ver 0.2.0

This library serializes and deserializes items to the SLONE formatting
specification.

SLONE stands for Serialized Lists [of] Ordered Named Elements.

This library uses the LONE collection datatype, which is a generic
List of Ordered Named Elements.

In the Nim language's library, two persistent constants are introduced,
``nothing`` and ``null``.

An example schema named "person.slone":

.. code:: slone1.0

    #! SLONE 1.0
    _ : field = {
      "name" : name = "person_id"
      "type" : type = "uuid"
      "element" : element = "value"
      "required" : int = "1"
    }
    _ : field = {
      "name" : name = "full name"
      "type" : type = "name"
      "element" : element = "value"
      "required" : int = "1"
    }
    _ : field = {
      "name" : name = "mailing address"
      "type" : type = "address_label"
      "element" : element = "list"
      "children" : children = {
        _ : field = {
          "element" : element = "string"
          "type": type = "line"
          "required" : int = "2"
        }
      }
    }
    _ : field = {
      "name" : name = "age"
      "type" : type = "uint8"
      "element" : element = "value"
    }

For the above example schema, all of the following are valid documents:

.. code:: slone1.0

    #! SLONE 1.0
    #% person.slone
    "person_id" : uuid = "12e38e63-f8ed-43dd-a525-db56a09b37cb"
    "full name" : name = "Joe Smith"
    "mailing address" : address_label = {
      _ : line = "123 Main St"
      _ : line = "Anytown, ST 12345"
    }
    "age" : uint8 = ?

.. code:: slone1.0

    #! SLONE 1.0
    #% person.slone
    "person_id" : uuid = "ba3a0310-dd3c-4cce-b9d6-da92d2b48f6b"
    "full name" : name = "Mary Doe"
    "address" : address_label = {
      _ : line = "Unit B"
      _ : line = "Floor 32"
      _ : line = "3434 Uptown Ave"
      _ : line = "New York, NY"
    }

.. code:: slone1.0

    #! SLONE 1.0
    #% person.slone
    "person_id" = "07d58ec6-1e44-4a57-839a-f01c5e20913c"
    "full name" = "John Dine"
    "age" = "62"

The code used to generate the first document above:

.. code:: nim

    import slone
    import slone/uuids

    var id = genUUID()
    var age: Option[int32] = null

    var doc = newLone()
    doc["person_id"] = id                             # a real UUID is serialized as a string (from slone/uuids lib)
    doc["full name"] = "Joe Smith"
    doc["age"] = age
    doc["mailing address"] = newLone()
    doc["mailing address"].add(nothing, "123 Main St")
    doc["mailing address"].add(nothing, "Anytown, ST 12345")

    echo $doc                                                  # serialized but without schema or types
    echo doc.seriallize(1.0, schemaFile="person.slone")        # serialized and re-ordered per schema; with full type annotations
    echo doc.serializeUntyped(1.0, schemaFile="person.slone")  # serialized and re-ordered per schema; but with no type annotations




Table Of Contents
=================

1. `Introduction to slone <https://github.com/JohnAD/slone>`__
2. Appendices

    A. `slone Reference <slone-ref.rst>`__
