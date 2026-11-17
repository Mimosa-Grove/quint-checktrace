module UnitCollision {
  type Tag = { tag: str }

  var b: Tag

  val tagIsUnit = b.tag == "UNIT"
}