module Rec3 {
  type P = { s: str, e: str, c: List[str] }
  var p: P
  val ok = p.s == "E"
}
