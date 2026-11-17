module RecB {
  type W = { s: int, e: int, c: List[int] }
}

module RecA {
  type WInt = int
}

module Main {
  import RecB.*
  import RecA.*
  var w: W

  val isTheRecord = w == { s: 1, e: 0, c: [1] }
}
