# personal-landing-page

An 8-bit themed personal landing page for Edson Ma, served by a small
[HTTP.jl](https://github.com/JuliaWeb/HTTP.jl) server and deployed on Railway
at <https://edsonma.cc>.

## Layout

```
├── app.jl               # HTTP.jl server: serves public/ from memory, security headers, gzip
├── Project.toml         # Julia deps (HTTP)
├── create_sysimage.jl   # PackageCompiler script (bakes HTTP.jl for fast boots)
├── Dockerfile           # Runtime image (runs as a non-root user)
├── Dockerfile.base      # Heavy layer: Julia + sysimage, built by GitHub Actions
├── railway.json         # Railway build/deploy settings (healthcheck: /healthz)
└── public/
    ├── index.html       # The landing page (single file)
    ├── robots.txt
    └── img/             # Project thumbnails (cached for a year)
```

## Run locally

```fish
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. app.jl
```

Then open <http://localhost:8000>. Set `PORT` to change the port.

## Deploy

Railway builds the `Dockerfile` on every push to `main`. The page is
pre-gzipped at build time and every response carries a strict
Content-Security-Policy and other security headers (see `app.jl`).

Optional: `.github/workflows/base-image.yml` publishes the Julia + sysimage
layer to `ghcr.io/edsonma/personal-landing-page-base`. Pointing the Dockerfile's
`FROM` at it makes deploys take seconds instead of minutes.

## Adding images

Put files in `public/img/` and reference them as `/img/name.jpg`. Keep them
small (a few KB to tens of KB): every visitor downloads them.
