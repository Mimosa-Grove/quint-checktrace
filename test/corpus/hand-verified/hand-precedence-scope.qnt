module HandPrecedenceScope {
  var count: int

  val nonNegative = count >= 0
  val zeroDiv = 10 / (1 - count) < 0
}