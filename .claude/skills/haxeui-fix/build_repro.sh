#!/usr/bin/env bash
#
# Builds a single-file HaxeUI XML repro into a static page (haxeui-html5, default theme).
#
# Usage: build_repro.sh <repro.xml> <out-dir> [<haxeui-core git ref>]
#   <out-dir>   created if missing; existing files in it are overwritten, nothing is deleted
#   <ref>       build against this commit of haxeui-core (e.g. upstream/master, or a fix branch).
#               The haxelib checkout is switched to it for the build and switched back afterwards,
#               so it must have no uncommitted changes. Without <ref>, builds against the checkout as is.
#
# The repro's XML is embedded at compile time: rebuild after every edit. Serve <out-dir> over HTTP
# (e.g. python -m http.server 5600 --bind 127.0.0.1 --directory <out-dir>); opening the file
# directly doesn't work.

set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "Usage: $0 <repro.xml> <out-dir> [<haxeui-core git ref>]" >&2
    exit 2
fi

xml=$(realpath "$1")
out="$2"
ref="${3:-}"
harness="$(cd "$(dirname "$0")" && pwd)/harness"
lib=$(haxelib libpath haxeui-core)

if [ -n "$ref" ]; then
    if [ -n "$(git -C "$lib" status --porcelain)" ]; then
        echo "haxeui-core checkout ($lib) has uncommitted changes - refusing to switch it." >&2
        exit 1
    fi

    original=$(git -C "$lib" symbolic-ref -q --short HEAD || git -C "$lib" rev-parse HEAD)
    trap 'git -C "$lib" checkout -q "$original"' EXIT
    git -C "$lib" checkout -q --detach "$ref"
fi

mkdir -p "$out"
cp "$xml" "$out/repro.xml"
cp "$harness/Main.hx" "$harness/index.html" "$out/"

(cd "$out" && haxe -cp . -main Main -lib haxeui-core -lib haxeui-html5 -js repro.js)

echo "Built $out against haxeui-core $(git -C "$lib" rev-parse --short HEAD)${ref:+ ($ref)}"
