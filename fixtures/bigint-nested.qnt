module NestedBig {
  type Row = { n: int }

  var r: Row
  var l: List[int]
  var s: Set[int]
  var m: str -> int
  var t: (int, int)

  val belowZero = r.n < 0
}