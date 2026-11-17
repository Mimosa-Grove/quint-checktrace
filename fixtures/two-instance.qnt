module Spec {
  const C: int

  var x: int

  action init = x' = C
  action step = x' = x + 1

  val bounded = x <= C + 2
}

module TwoInstances {
  import Spec(C = 0) as a
  import Spec(C = 10) as b

  action init = all { a::init, b::init }
  action step = all { a::step, b::step }

  val both = a::bounded and b::bounded
}