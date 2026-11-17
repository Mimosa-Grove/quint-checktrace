module Lib {
  var v: int
}

module StarMain {
  import Lib.*
  var w: int

  val ok = w >= 0
}
