# Julia + HTTP.jl — works on fly.io or Railway (sysimage build included
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

# Bake HTTP.jl into a custom sysimage so runtime boot is fast (seconds,
# not minutes). This build step itself takes several minutes — that's
# a one-time cost at build time, not something fly's deploy-readiness
# timeout has to wait through on every boot.
COPY create_sysimage.jl ./
RUN julia --project=. create_sysimage.jl

# Now copy the rest of the app
COPY . .

# Pre-compress the landing page; app.jl serves it to gzip-capable clients.
RUN gzip -9 -k -f public/index.html

# Memory tuning for a tiny single-purpose server: one Julia thread, fewer glibc
# malloc arenas (the default is 8x cores and fragments badly), and return freed
# pages to the OS sooner.
ENV JULIA_NUM_THREADS=1
ENV MALLOC_ARENA_MAX=2
ENV MALLOC_TRIM_THRESHOLD_=131072
ENV PORT=8000
ENV HOST=0.0.0.0

EXPOSE 8000

# Boot using the precompiled sysimage instead of plain `julia`,
# so HTTP.jl is already loaded in memory at process start — this is
# what gets us under fly's deploy-readiness timeout.
CMD ["julia", "--project=.", "--sysimage=/app/AppSysimage.so", "--heap-size-hint=128M", "--gcthreads=1", "app.jl"]
