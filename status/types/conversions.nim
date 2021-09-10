
import
  json_serialization, json_serialization/lexer, stew/results, web3/conversions

export
  results

proc writeValue*[V, E](writer: var JsonWriter, value: Result[V, E]) =
  writer.beginRecord(type(value))
  writer.writeField("o", value.isOk)
  if value.isOk:
    when V isnot void:
      writer.writeField("v", value.get)
  else:
    writer.writeField("e", value.error)
  writer.endRecord()

proc readValue*[V, E](reader: var JsonReader, value: var Result[V, E]) =
  # {"o":true} - void value type
  # {"o":true, "v":"some val"} - string value type
  # {"o":false, "e":0} - if the error type is an enum, will be an int
  reader.skipToken tkCurlyLe

  let oName = reader.readValue(string)
  if oName != "o":
    reader.raiseUnexpectedValue("Missing field 'o'")
  reader.skipToken tkColon
  let o = reader.readValue(bool)

  if o:
    when V is void:
      value = Result[V, E].ok()

    when V isnot void:
      reader.skipToken tkComma
      let vName = reader.readValue(string)
      if vName != "v":
        reader.raiseUnexpectedValue("Missing field 'v'")
      reader.skipToken tkColon
      let v = reader.readValue(V)

      value = Result[V, E].ok v

  else:
    reader.skipToken tkComma
    let eName = reader.readValue(string)
    if eName != "e":
      reader.raiseUnexpectedValue("Missing field 'e'")
    reader.skipToken tkColon
    let e = reader.readValue(E)

    value = Result[V, E].err e

  reader.skipToken tkCurlyRi
