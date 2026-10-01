# Julia + Genie.jl — works on fly.io or Railway (sysimage build included
# for fast cold boots; Railway's healthcheckTimeout in railway.json
# already gives it plenty of room on the very first deploy)
FROM julia:1.10-bookworm

WORKDIR /app

# PackageCompiler needs a full C/C++ toolchain to link the sysimage —
# gcc alone isn't enough (missing libc6-dev means no crti.o, and no
# g++ means it falls back to gcc for C++ bits and fails to link).
# build-essential pulls in gcc, g++, make, and libc6-dev together.
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

# Set the depot path before installing anything, so the package
# install and runtime agree on where packages live.
ENV JULIA_DEPOT_PATH=/usr/local/share/julia

# Copy only the manifest files first so Julia's package
# install layer is cached unless dependencies change.
COPY Project.toml ./
RUN julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.add("PackageCompiler"); Pkg.precompile()'

# Bake Genie into a custom sysimage so runtime boot is fast (seconds,
# not minutes). This build step itself takes several minutes — that's
# a one-time cost at build time, not something fly's deploy-readiness
# timeout has to wait through on every boot.
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
# so Genie is already loaded in memory at process start — this is
# what gets us under fly's deploy-readiness timeout.
CMD ["julia", "--project=.", "--sysimage=/app/GenieSysimage.so", "app.jl"]
