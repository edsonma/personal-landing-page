# edsonma — Personal Landing Page

An 8-bit themed personal landing page, served through a [Genie.jl](https://genieframework.com/)
app so it can live alongside future Julia-powered demos (e.g. a live
LightGraphs.jl render of the stack graph) on the same deployment.

## Project structure

```
personal-landing-page/
├── app.jl                 # Genie app entry point — serves public/index.html at "/"
├── Project.toml            # Julia package manifest (Genie dependency)
├── config/
│   └── env/prod.jl         # Production server config
├── public/
│   └── index.html          # The landing page itself (static HTML/CSS/JS)
├── Dockerfile               # Builds the Julia + Genie image
├── fly.toml                 # fly.io app configuration
├── .dockerignore
└── .gitignore
```

## Run locally

Requires Julia 1.9+.

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. app.jl
```

Then open http://localhost:8000.

## Deploy to fly.io

1. Install the [flyctl CLI](https://fly.io/docs/flyctl/install/) if you haven't:
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. Log in:
   ```bash
   fly auth login
   ```

3. Launch the app (first time only — this reads `fly.toml` and asks to confirm):
   ```bash
   fly launch --no-deploy
   ```
   Keep the existing `fly.toml` when prompted, or adjust `app` name / region as needed.

4. Deploy:
   ```bash
   fly deploy
   ```

5. Open it:
   ```bash
   fly open
   ```

Future deploys are just `fly deploy` again after pushing changes.

## Adding real Julia functionality

`app.jl` already has a `/healthz` route fly.io uses for health checks. To add a
Julia-powered endpoint — for example, generating the stack graph live with
`LightGraphs.jl` instead of the hand-authored SVG — add a new `route(...)` block
in `app.jl` and add the package to `Project.toml`.

## License

Personal project — all rights reserved by Edson Ma.
