module Lib {
  var v: int
}

module AliasMain {
  import Lib as L
  var w: int

  val ok = w >= 0
}
