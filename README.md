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
- **Search:** Algolia (index `tuzov.dev`).
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

## Search index

Algolia is fed from `public/index.json`, which Hugo emits from the JSON
output format (see `[outputs]` in `config.toml`). That single file is
the only thing under `public/` tracked in git.

Regenerate it with a normal build, then commit the updated file:

```bash
hugo --gc
git add public/index.json
```

The GitHub Actions workflow `.github/workflows/algolia-uploader.yaml`
uploads `public/index.json` to the `tuzov.dev` Algolia index and runs on
demand (`workflow_dispatch`); it needs the `ALGOLIA_ADMIN_KEY` secret.
