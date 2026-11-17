module RecB {
  type W = { s: int, e: int, c: List[int] }
}

module RecA {
  type W = int
}

module Other {
  import RecA.*
  var z: W
}

module Main {
  import RecB.*
  var w: W

  val isTheRecord = w == { s: 1, e: 0, c: [1] }
  val recordIsNotOne = w == 1
}
