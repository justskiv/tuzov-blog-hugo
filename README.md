# tuzov.dev

Personal tech blog at <https://tuzov.dev/>, built with the
[Hugo](https://gohugo.io/) static site generator. Content is in Russian
and focuses on Go and backend development.

## Stack

- **Generator:** Hugo (extended). Built with `v0.154.5+extended`; any
  recent extended release should work.
- **Theme:** `justskiv-loveit` — a custom fork of the
  [LoveIt](https://github.com/dillonzq/LoveIt) theme, wired in as a git
  submodule under `themes/justskiv-loveit/`. Site-specific style
  overrides live in `assets/css/_override.scss`.
- **Search:** [Pagefind](https://pagefind.app/) — fully local, built at
  deploy time, no external API.
- **Comments:** self-hosted Remark42 at `remark42.tuzov.dev`.
- **Analytics:** Yandex Metrica.

## Local development

The theme is a git submodule, so fetch it once after cloning:

```bash
git submodule init
git submodule update
```

Then run the dev server with hot reload:

```bash
hugo server
```

Build the static site into `public/`:

```bash
hugo --gc --minify
```

A `Taskfile.yml` wraps the common commands (`task --list` to see them).

## Deployment

The site is hosted on **Cloudflare Pages**. Cloudflare builds and
publishes the project from the repository, so a normal push to the
production branch ships the site — no manual upload of `public/` is
needed.

## Search

Search is fully local via [Pagefind](https://pagefind.app/) — no external
API. Pagefind indexes the rendered HTML after the Hugo build and writes the
index plus a lazy-loaded WASM runtime into `public/pagefind/`. The `build`
task runs it automatically (`npx -y pagefind@1 --site public`), and
Cloudflare Pages does the same via its build command
(`hugo && npx -y pagefind@1 --site public`).

Pagefind needs built HTML on disk, which `hugo server` does not produce, so
to test search locally build and serve the static output:

```bash
task search:preview
```
