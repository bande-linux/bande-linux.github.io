#!/bin/bash
# Renders the site into _site/ from the newest bande-linux/images release.
# Usage: build.sh [release.json]
# With a file, it is used instead of the GitHub API.
set -euo pipefail
export LC_ALL=C.UTF-8

here=$(cd "$(dirname "$0")" && pwd)
out=${OUT:-$here/_site}
repo=${IMAGES_REPO:-bande-linux/images}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fixture=${1:-}
if [ -n "$fixture" ]; then
    cp "$fixture" "$work/release.json"
elif gh api "repos/$repo/releases/latest" > "$work/release.json" 2> "$work/error"; then
    :
elif grep -q 'HTTP 404' "$work/error"; then
    rm "$work/release.json"
else
    cat "$work/error" >&2
    exit 1
fi

tag='' date='' release_url=''
declare -A size digest url
names=()
if [ -f "$work/release.json" ]; then
    while IFS=$'\t' read -r kind a b c d; do
        case $kind in
            release) tag=$a date=$b release_url=$c ;;
            asset) names+=("$a") size[$a]=$b digest[$a]=${c#sha256:} url[$a]=$d ;;
        esac
    done < <(python3 -I -c '
import json, sys
r = json.load(open(sys.argv[1]))
print("release", r["tag_name"], r["published_at"][:10], r["html_url"], sep="\t")
for a in r["assets"]:
    print("asset", a["name"], a["size"], a.get("digest") or "-", a["browser_download_url"], sep="\t")
' "$work/release.json")
fi

find_asset() {
    local name
    for name in "${names[@]}"; do
        # shellcheck disable=SC2254
        case $name in $1) echo "$name"; return ;; esac
    done
}

html() {
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' <<< "$1"
}

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
    for nav in '@CONTENT@' '@NAV_' '@TITLE@' '@CARDS@' '@RELEASE@'; do
        if grep -q "$nav" "$target"; then
            echo "build.sh: $nav left in $target" >&2
            exit 1
        fi
    done
}

pretty_date() {
    date -u -d "$1" '+%-d %B %Y'
}

card() {
    local title=$1 for=$2 file=$3 steps=$4
    [ -n "$file" ] || return 0
    echo '<article class="card">'
    echo "  <h2>$title</h2>"
    echo "  <p>$for</p>"
    local sha=${digest[$file]}
    [ "$sha" = - ] && sha='see the release page'
    cat <<EOF
  <dl>
    <dt>File</dt><dd>$(html "$file")</dd>
    <dt>Size</dt><dd>$(numfmt --to=iec-i --suffix=B --format=%.1f "${size[$file]}")</dd>
    <dt>SHA256</dt><dd class="sha">$(html "$sha")</dd>
    <dt>Date</dt><dd>$(pretty_date "$date")</dd>
  </dl>
$steps
  <a class="button" href="$(html "${url[$file]}")">Download</a>
</article>
EOF
}

rm -rf "$out"
mkdir -p "$out"
cp "$here/style.css" "$out/"
touch "$out/.nojekyll"

amd64_iso=$(find_asset 'bande-os-*-amd64.iso')
arm64_iso=$(find_asset 'bande-os-*-arm64.iso')

if [ -n "$tag" ]; then
    echo "<p>Release <a href=\"$(html "$release_url")\">$(html "$tag")</a>, built $(pretty_date "$date"). An installed system is updated through apt.</p>" > "$work/release.html"
else
    echo '<p>No install media are published yet.</p>' > "$work/release.html"
fi

pc_steps='  <ol>
    <li>Write the ISO to a USB drive.</li>
    <li>Boot the machine from the drive in UEFI mode.</li>
    <li>The Debian installer partitions the disk and installs Bande.</li>
  </ol>'

{
    card 'amd64' 'amd64 machines with UEFI.' "$amd64_iso" "$pc_steps"
    card 'arm64' 'arm64 machines with UEFI.' "$arm64_iso" "$pc_steps"
} > "$work/cards.tmp"
if [ -s "$work/cards.tmp" ]; then
    { echo '<section class="cards">'; cat "$work/cards.tmp"; echo '</section>'; } > "$work/cards.html"
else
    : > "$work/cards.html"
fi

fill "$here/pages/download.html" @RELEASE@ "$work/release.html" > "$work/download.tmp"
fill "$work/download.tmp" @CARDS@ "$work/cards.html" > "$work/download.html"

render HOME 'Bande' "$here/pages/index.html" "$out/index.html"
render DOWNLOAD 'Download Bande' "$work/download.html" "$out/download/index.html"
render DEBIAN 'Install Bande on Debian 14' "$here/pages/debian.html" "$out/debian/index.html"

if [ -n "$tag" ]; then
    echo "Built $out from $repo $tag"
else
    echo "Built $out; $repo has no release yet"
fi
