using Genie
using Genie.Router
using Genie.Renderer

# Read the landing page once at startup instead of on every request —
# avoids allocating a fresh ~100 KB string per hit, which keeps the GC
# from letting the heap balloon.
const INDEX_HTML = read(joinpath(@__DIR__, "public", "index.html"), String)

# Serve the static landing page at the root route.
route("/") do
  Genie.Renderer.WebRenderable(INDEX_HTML, :html) |> Genie.Renderer.respond
end

# Simple healthcheck endpoint — fly.io pings this to confirm
# the app booted correctly.
route("/healthz") do
  "ok"
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
