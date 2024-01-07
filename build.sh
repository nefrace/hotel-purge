#!/bin/bash
source ./config.sh
rm -f $OUT_CART $OUT_BIN
odin build src -out:$OUT_BIN -target:freestanding_wasm32 -no-entry-point -extra-linker-flags:"--import-memory -zstack-size=8192 --initial-memory=262144 --max-memory=262144 --global-base=98304 --lto-O3 --gc-sections --strip-all"
tic80 --skip --fs . --cmd "load $IN_CART & import binary $OUT_BIN & save $OUT_CART & run & exit"