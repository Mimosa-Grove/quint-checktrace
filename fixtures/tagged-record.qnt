module Tagged {
  type TaggedRecord = { tag: str, value: int, extra: int }

  var r: TaggedRecord

  val tagIsX = r.tag == "x"
}