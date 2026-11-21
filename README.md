# bande-linux.github.io

The Bande website, served by GitHub Pages at <https://bande-linux.github.io>. It is plain
HTML and CSS: `template.html` wraps each page in `pages/`, and `build.sh` renders them into
`_site/`.

The apt archive at `/apt` is the `apt` repository's own Pages site; this repository must not
have an `apt/` directory.

## Build

```bash
./build.sh
```

It reads the newest release of `bande-linux/images` with `gh api` (set `IMAGES_REPO` to read
another repository) and fills in the download page. With no release the page says that no media are published.
To render a fake release, pass a release JSON:

```bash
OUT=$PWD/_fixture ./build.sh tests/release.json
```

Preview with `python3 -m http.server -d _site`.

## What the images release must contain

| Asset | Used for |
|---|---|
| `bande-os-<date>-amd64.iso` | amd64 card |
| `bande-os-<date>-arm64.iso` | arm64 card |

Sizes and SHA256 come from the release's asset metadata. A card is left out when its ISO is
not in the release.

## Deploy

`.github/workflows/pages.yml` builds and deploys on every push to `main` and on
`workflow_dispatch`, which the images workflow sends after it publishes. The default token can
read `bande-linux/images` only while that repository is public.
