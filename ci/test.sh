#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash ci/build.sh
source ci/env.sh
export CAML_LD_LIBRARY_PATH="$PWD/build:${CAML_LD_LIBRARY_PATH:-}"
for target in adapter lifetime; do
 ocamlfind ocamlc -package yojson -linkpkg -I build build/licensebox.cma "test/$target.ml" -o "build/$target"
done
ocamlrun build/lifetime
mkdir -p build/install
if [[ -d build/install/licensebox ]]; then OCAMLFIND_DESTDIR="$PWD/build/install" ocamlfind remove -ldconf ignore licensebox; fi
OCAMLFIND_DESTDIR="$PWD/build/install" ocamlfind install -ldconf ignore licensebox build/META build/licensebox.cma build/licensebox.cmi build/liblicensebox_stubs.a build/dlllicensebox_stubs.so
tar -czf build/licensebox-ocaml-0.3.0.tar.gz LICENSE src ci test licensebox.opam
