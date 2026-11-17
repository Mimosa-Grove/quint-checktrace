(lang dune 3.17)
(name quint-checktrace)
(version 0.1.0)
(generate_opam_files true)

(package
 (name quint-checktrace)
 (synopsis "Trace-to-specification conformance for Quint")
 (depends ocaml dune cmdliner alcotest qcheck))
