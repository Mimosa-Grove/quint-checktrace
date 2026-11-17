module Plain {
  var count: int
  var log: List[int]

  val nonNegative = count >= 0
  val logLengthMatches = log.length() == count
}