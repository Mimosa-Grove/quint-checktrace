module Inner {
  const C: int

  var x: int

  action init = x' = C
  action step = x' = x + 1

  val inRange = x <= C + 3
}

module Mid {
  const D: int

  import Inner(C = D) as i

  var y: int

  action init = all { i::init, y' = D }
  action step = all { i::step, y' = y + 1 }

  val nested = i::inRange and y >= 0
}

module Outer {
  import Mid(D = 0) as m

  action init = m::init
  action step = m::step

  val deep = m::nested
}