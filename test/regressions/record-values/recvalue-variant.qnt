module RW {
  type W = { s: int, e: int, c: List[int] }
  type V = A(W) | B(int)
  var v: V

  val ok = true
}
