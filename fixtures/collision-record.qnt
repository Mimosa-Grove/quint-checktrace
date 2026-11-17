module Collision {
  type TaggedRecord = { tag: str, value: int }

  var r: TaggedRecord

  val tagIsHello = r.tag == "hello"
}