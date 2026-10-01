# Julia + Genie.jl, built for fly.io
FROM julia:1.10-bookworm

WORKDIR /app

# PackageCompiler needs a C compiler on PATH to link the sysimage —
# the base julia image doesn't ship one.
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

# Set the depot path before installing anything, so the package
# install and runtime agree on where packages live.
ENV JULIA_DEPOT_PATH=/usr/local/share/julia

# Copy only the manifest files first so Julia's package
# install layer is cached unless dependencies change.
COPY Project.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.add("PackageCompiler"); Pkg.precompile()'

# Bake Genie into a custom sysimage. This is the real fix for slow
# cold boots on fly.io: without it, every container start pays
# Julia's full "using Genie" JIT cost from scratch (often 60-120s+),
# which was timing out fly's proxy before the app ever got to
# listening. This step takes a few extra minutes at build time —
# that's a one-time cost, not something fly.io's health check
# has to wait through on every boot.
COPY create_sysimage.jl ./
RUN julia --project=. create_sysimage.jl

# Now copy the rest of the app
COPY . .

ENV GENIE_ENV=prod
ENV PORT=8000
ENV HOST=0.0.0.0
ENV GENIE_HOST=0.0.0.0

EXPOSE 8000

# Boot using the precompiled sysimage instead of plain `julia`,
# so Genie is already loaded in memory at process start.
CMD ["julia", "--project=.", "--sysimage=/app/GenieSysimage.so", "app.jl"]
