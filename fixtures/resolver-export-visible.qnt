module ExportSpec {
  const K: int

  val exported = K == 8
}

module ExportBridge {
  import ExportSpec(K = 7) as e
  export e
}

module ExportHolder {
  import ExportBridge.*

  var x: int

  val visible = x >= 0
}