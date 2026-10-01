# Julia + Genie.jl, built for fly.io
FROM julia:1.10-bookworm

WORKDIR /app

# Set the depot path before installing anything, so the package
# install (next step) and the runtime CMD agree on where packages
# live.
ENV JULIA_DEPOT_PATH=/usr/local/share/julia

# Copy only the manifest files first so Julia's package
# install layer is cached unless dependencies change.
#
# Pkg.precompile() on Julia 1.9+ already caches compiled native
# code for every package (not just parsed syntax) — this is the
# same mechanism a custom PackageCompiler sysimage would give us,
# built in, with no C toolchain required. That's what actually
# keeps runtime "using Genie" fast.
COPY Project.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# Now copy the rest of the app
COPY . .

ENV GENIE_ENV=prod
ENV PORT=8000
ENV HOST=0.0.0.0
ENV GENIE_HOST=0.0.0.0

EXPOSE 8000

CMD ["julia", "--project=.", "app.jl"]
