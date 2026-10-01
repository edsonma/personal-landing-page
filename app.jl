using Genie
using Genie.Router
using Genie.Renderer

# Serve the static landing page at the root route.
route("/") do
  Genie.Renderer.WebRenderable(
    read(joinpath(@__DIR__, "public", "index.html"), String),
    :html
  ) |> Genie.Renderer.respond
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

up(Genie.config.server_port, Genie.config.server_host; async = false, verbose = true)
