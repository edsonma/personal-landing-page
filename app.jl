using Genie
using Genie.Router
using Genie.Renderer

# Read the landing page once at startup instead of on every request —
# avoids allocating a fresh string per hit, which keeps the GC from
# letting the heap balloon.
const INDEX_PATH = joinpath(@__DIR__, "public", "index.html")
const INDEX_HTML = read(INDEX_PATH, String)

# The Dockerfile pre-compresses the page (index.html.gz) at build time, which
# cuts egress by ~75%. If the .gz is missing (local dev) we serve plain HTML.
const INDEX_GZ = isfile(INDEX_PATH * ".gz") ? read(INDEX_PATH * ".gz") : nothing

accepts_gzip() = try
  occursin("gzip", lowercase(string(Genie.Router.params(:REQUEST).headers)))
catch
  false
end

# Serve the static landing page at the root route.
route("/") do
  if INDEX_GZ !== nothing && accepts_gzip()
    try
      return Genie.Renderer.WebRenderable(INDEX_GZ, :html, 200,
        Dict("Content-Encoding" => "gzip", "Vary" => "Accept-Encoding",
             "Cache-Control" => "public, max-age=300")) |> Genie.Renderer.respond
    catch e
      @warn "gzip response failed, falling back to plain HTML" exception = e
    end
  end
  Genie.Renderer.WebRenderable(INDEX_HTML, :html) |> Genie.Renderer.respond
end

# Simple healthcheck endpoint — fly.io pings this to confirm
# the app booted correctly.
route("/healthz") do
  "ok"
end

# Thumbnails in public/img/ are served by Genie's static file handler;
# let browsers cache them for a year instead of re-downloading each visit.
try
  Genie.config.cache_duration = 31536000
catch e
  @warn "could not set cache_duration" exception = e
end

Genie.config.run_as_server = true
Genie.config.server_host = "0.0.0.0"
Genie.config.server_port = parse(Int, get(ENV, "PORT", "8000"))
Genie.config.websockets_port = Genie.config.server_port

# Print exactly what we're about to bind to — this is what fly's
# error hint ("look at your startup logs") is asking you to check.
println("Starting Genie on host=$(Genie.config.server_host) port=$(Genie.config.server_port)")
flush(stdout)

up(Genie.config.server_port, Genie.config.server_host; async = false)
