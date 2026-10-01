# Julia + Genie.jl, built for fly.io
FROM julia:1.10-bookworm

WORKDIR /app

# Copy only the manifest files first so Julia's package
# install layer is cached unless dependencies change.
COPY Project.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'

# Now copy the rest of the app
COPY . .

ENV JULIA_DEPOT_PATH=/usr/local/share/julia
ENV GENIE_ENV=prod
ENV PORT=8000
ENV HOST=0.0.0.0
ENV GENIE_HOST=0.0.0.0

EXPOSE 8000

CMD ["julia", "--project=.", "app.jl"]
