(lang dune 3.17)
(name quint-checktrace)
(version 0.1.0)
(generate_opam_files true)

(package
 (name quint-checktrace)
 (synopsis "Trace-to-specification conformance for Quint")
 (description
  "Checks recorded execution traces against a Quint specification's invariants, with a digest-pinned evaluator and a CI gate")
 (depends ocaml dune cmdliner alcotest qcheck)
 (authors "Phill Clarke <phill@mimosadev.org>")
 (maintainers "Phill Clarke <phill@mimosadev.org>")
 (license "AGPL-3.0-or-later")
 (homepage "https://github.com/Mimosa-Grove/quint-checktrace")
 (bug_reports "https://github.com/Mimosa-Grove/quint-checktrace/issues")
 (source (github Mimosa-Grove/quint-checktrace)))
