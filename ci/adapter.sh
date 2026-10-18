#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source ci/env.sh
export CAML_LD_LIBRARY_PATH="$PWD/build:${CAML_LD_LIBRARY_PATH:-}"
exec ocamlrun build/adapter
