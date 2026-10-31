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
another repository) and fills in the download cards. With no release it renders "coming soon".
To render a fake release, pass a release JSON; its assets are read from `assets/` next to it:

```bash
OUT=$PWD/_fixture ./build.sh tests/release.json
```

Preview with `python3 -m http.server -d _site`.

## What the images release must contain

| Asset | Used for |
|---|---|
| `bande-os-apple-<date>.zip` | Mac mini M2 card; the installer downloads it |
| `installer-<version>.tar.gz` | the Mac installer that `install` downloads |
| `installer_data.json` | served at `/installer_data.json`, with `package` made an absolute release URL |
| `bande-os-<date>-amd64.iso` | PC card |
| `bande-os-<date>-arm64.iso` | arm64 card |

Sizes and SHA256 come from the release's asset metadata. The Mac card stays "coming soon" until
the zip, the installer tarball and `installer_data.json` are all in the same release.

## The Mac bootstrap

`install` is `installer/scripts/bootstrap.sh` with the hosted URLs. `build.sh` sets
`INSTALLER_BASE` to the release's download URL and writes the installer version to
`/installer/latest`, so it always matches the image it serves:

```bash
curl -L https://bande-linux.github.io/install | sh
```

## Deploy

`.github/workflows/pages.yml` builds and deploys on every push to `main` and on
`workflow_dispatch`, which the images workflow sends after it publishes. The default token can
read `bande-linux/images` only while that repository is public.
