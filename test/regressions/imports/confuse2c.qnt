module RecB {
  type W = { s: int, e: int, c: List[int] }
}

module RecA {
  type W = int
}

module Main {
  import RecB.*
  var w: W

  val isTheRecord = w == { s: 1, e: 0, c: [1] }
  val recordIsNotOne = w == 1
}

module Other {
  import RecA.*
  val usesA: W = 0
}
