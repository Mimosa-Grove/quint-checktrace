module Bigs {
  var a: int
  var b: int
  var c: int
  var d: int

  val ok = a >= -1000000
  val exact = and {
    a == 1000000000000000,
    b == 9007199254740993,
    c == 999999999999999999,
    d == -9007199254740993,
  }
}