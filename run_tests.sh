#!/usr/bin/env bash
# run_tests.sh - the repository gates, in order:
#   1. dune build, including the corpus generator;
#   2. fixture regeneration: the generator re-runs in a scratch copy and the
#      result must be byte-identical to the committed fixture tree;
#   3. specification parsing: every fixture specification parses with the
#      pinned Quint;
#   4. dune runtest: the report and gate fixtures, the resolver cases, the
#      schema expected pairs and the seed-controlled property runner.
# Licence: AGPL-3.0-or-later; see README.md.
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
QUINT="${QUINT:-quint}"
QUINT_VERSION="0.33.1"
SPEC_COUNT="134"
fail=0

# 1. OCaml library, checker and corpus generator.
DUNE=()
if command -v opam >/dev/null 2>&1; then
  DUNE=(opam exec -- dune)
elif command -v dune >/dev/null 2>&1; then
  DUNE=(dune)
else
  echo "FAIL dune: not on PATH"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  if "${DUNE[@]}" build; then
    echo "PASS dune build"
  else
    echo "FAIL dune build"
    fail=1
  fi
fi

# 2. Fixture regeneration: the committed corpus must be the generator output.
if [ "$fail" -eq 0 ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  cp -a "$DIR/fixtures" "$tmp/fixtures"
  if ! "$DIR/_build/default/maintenance/build_fixtures.exe" --root "$tmp" \
      > "$tmp/generate.log" 2>&1; then
    echo "FAIL fixture regeneration: generator exited non-zero"
    head -n 40 "$tmp/generate.log"
    fail=1
  elif ! diff -r "$DIR/fixtures" "$tmp/fixtures" > "$tmp/diff.log" 2>&1; then
    echo "FAIL fixture regeneration: committed tree differs from generator output"
    head -n 40 "$tmp/diff.log"
    fail=1
  else
    echo "PASS fixture regeneration"
  fi
  rm -rf "$tmp"
  trap - EXIT
fi

# 3. Specification parsing with the pinned Quint.
if ! command -v "$QUINT" >/dev/null 2>&1; then
  echo "FAIL quint: not on PATH and no QUINT override"
  fail=1
elif [ "$("$QUINT" --version 2>/dev/null)" != "$QUINT_VERSION" ]; then
  echo "FAIL quint: expected $QUINT_VERSION, got $("$QUINT" --version 2>/dev/null)"
  fail=1
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  shopt -s globstar nullglob
  specs=("$DIR"/fixtures/**/*.qnt)
  spec_count=0
  spec_fail=0
  for f in "${specs[@]}"; do
    spec_count=$((spec_count + 1))
    if ! "$QUINT" parse --out "$tmp/parse.ir.json" "$f" > "$tmp/parse.log" 2>&1; then
      echo "FAIL quint parse: ${f#$DIR/}"
      head -n 5 "$tmp/parse.log"
      spec_fail=1
    fi
  done
  if [ "$spec_fail" -eq 0 ] && [ "$spec_count" -eq "$SPEC_COUNT" ]; then
    echo "PASS quint parse: $spec_count specification files"
  elif [ "$spec_fail" -eq 0 ]; then
    echo "FAIL quint parse: expected $SPEC_COUNT specification files, found $spec_count"
    fail=1
  else
    echo "FAIL quint parse: $spec_count specification files, at least one refused"
    fail=1
  fi
  rm -rf "$tmp"
  trap - EXIT
fi

# 4. Alcotest suite and the property runner.
if [ "$fail" -eq 0 ]; then
  if "${DUNE[@]}" runtest; then
    echo "PASS dune runtest"
  else
    echo "FAIL dune runtest"
    fail=1
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "RESULT: pass"
else
  echo "RESULT: fail"
  exit 1
fi
