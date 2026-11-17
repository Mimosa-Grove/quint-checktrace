module BigRecord {
  type Chunks = { s: int, e: int, c: List[int], extra: int }

  var r: Chunks

  val extraIsSeven = r.extra == 7
}