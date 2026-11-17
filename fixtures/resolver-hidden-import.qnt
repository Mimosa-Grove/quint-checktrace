module HiddenSpec {
  const K: int

  val hidden = K == 8
}

module HiddenHolder {
  import HiddenSpec(K = 7) as h

  var x: int

  val visible = x >= 0
}