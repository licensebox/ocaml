# Validation — 2026-10-18

PASS: OCaml 4.14.1 + Yojson actual C-stub/library compilation, isolated ocamlfind install, repeated creation/close, callback exception containment, and all 69 shared protocol checks.

The C core was built as a shared library from the public SDK checkout. Test keys, times, identities and loopback server data are synthetic. Linux x86-64 only; other OS/runtime paths are unvalidated. No remote release or registry publication is performed by these scripts.
