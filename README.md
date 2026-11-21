# bande-linux.github.io

The Bande website, served by GitHub Pages at <https://bande-linux.github.io>. It is plain
HTML and CSS: `template.html` wraps each page in `pages/`, and `build.sh` renders them into
`_site/`.

The fonts in `fonts/` are the Bande desktop's: Inter, Manrope and JetBrains Mono, subset to Latin
and converted to WOFF2 from Debian's `fonts-inter`, `fonts-manrope` and `fonts-jetbrains-mono`
(SIL OFL 1.1, see `fonts/OFL.txt`).

The apt archive at `/apt` is the `apt` repository's own Pages site; this repository must not
have an `apt/` directory.

## Build

```bash
./build.sh
```

Preview with `python3 -m http.server -d _site`.

## Deploy

`.github/workflows/pages.yml` builds and deploys on every push to `main` and on
`workflow_dispatch`.
