using Genie
using Genie.Router
using Genie.Renderer

# Serve the static landing page at the root route.
# The file lives in public/index.html, and Genie's static
# file server already exposes everything under public/ —
# this route just makes "/" explicit and gives us a place
# to hook in Julia-powered endpoints later (e.g. a live
# LightGraphs.jl render of the stack graph).
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

up(Genie.config.server_port, "0.0.0.0"; async = false)
