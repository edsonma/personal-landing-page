# Julia + Genie.jl, built for fly.io
FROM julia:1.10-bookworm

WORKDIR /app

# Set the depot path BEFORE installing anything, so the package
# install (next step) and the runtime CMD agree on where packages
# live. Setting this after Pkg.instantiate() was a bug — Genie
# would get installed into the default depot, then the runtime
# ENV override pointed Julia at a different, empty directory,
# causing "Package Genie ... does not seem to be installed".
ENV JULIA_DEPOT_PATH=/usr/local/share/julia

# Copy only the manifest files first so Julia's package
# install layer is cached unless dependencies change.
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
