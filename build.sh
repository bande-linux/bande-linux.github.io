#!/bin/bash
# Usage: build.sh
# Renders the pages into _site/, or into $OUT.
set -euo pipefail
export LC_ALL=C.UTF-8

here=$(cd "$(dirname "$0")" && pwd)
out=${OUT:-$here/_site}

fill() {
    awk -v key="$2" -v file="$3" '
        index($0, key) { while ((getline line < file) > 0) print line; next }
        { print }
    ' "$1"
}

render() {
    local page=$1 title=$2 content=$3 target=$4 nav
    mkdir -p "$(dirname "$target")"
    fill "$here/template.html" @CONTENT@ "$content" |
        sed -e "s|@TITLE@|$title|" \
            -e "s|@NAV_$page@|aria-current=\"page\"|" \
            -e 's|@NAV_[A-Z]*@||' > "$target"
    for nav in '@CONTENT@' '@NAV_' '@TITLE@'; do
        if grep -q "$nav" "$target"; then
            echo "build.sh: $nav left in $target" >&2
            exit 1
        fi
    done
}

rm -rf "$out"
mkdir -p "$out"
cp -r "$here/style.css" "$here/fonts" "$out/"
touch "$out/.nojekyll"

render HOME 'Bande' "$here/pages/index.html" "$out/index.html"
render DEBIAN 'Install Bande on Debian 14' "$here/pages/debian.html" "$out/debian/index.html"

echo "Built $out"
