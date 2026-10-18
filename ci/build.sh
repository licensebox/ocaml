#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/env.sh
ocamlc -ccopt "-I$LICENSEBOX_INCLUDE_DIR" -c src/stubs.c -o build/stubs.o
ocamlfind ocamlc -package yojson -c src/licensebox.mli -o build/licensebox.cmi
ocamlfind ocamlc -package yojson -I build -c src/licensebox.ml -o build/licensebox.cmo
ocamlmklib -o build/licensebox_stubs build/stubs.o -L"$LICENSEBOX_LIB_DIR" -llicensebox
ocamlc -a -o build/licensebox.cma build/licensebox.cmo -dllib -llicensebox_stubs -cclib -llicensebox_stubs -cclib -llicensebox
cat > build/META <<'META'
version="0.2.0"
requires="yojson"
archive(byte)="licensebox.cma"
META
