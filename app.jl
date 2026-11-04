using HTTP

# Everything in public/ is read into memory once at startup (it is ~100 KB),
# so requests never touch the disk or allocate fresh buffers.
const PUBLIC = joinpath(@__DIR__, "public")
const PORT = parse(Int, get(ENV, "PORT", "8000"))

const CONTENT_TYPES = Dict(
  ".html" => "text/html; charset=utf-8",
  ".jpg"  => "image/jpeg",
  ".jpeg" => "image/jpeg",
  ".png"  => "image/png",
  ".svg"  => "image/svg+xml",
  ".ico"  => "image/x-icon",
  ".css"  => "text/css; charset=utf-8",
  ".js"   => "text/javascript; charset=utf-8",
  ".txt"  => "text/plain; charset=utf-8",
)

# Sent with every response. The page is fully static (no forms, no user input,
# no cookies), so the CSP can be strict: only its own files, Google Fonts, and
# inline styles/scripts (the page ships as a single self-contained HTML file).
const SECURITY_HEADERS = [
  "Content-Security-Policy" => join([
    "default-src 'none'",
    "script-src 'self' 'unsafe-inline'",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src https://fonts.gstatic.com",
    "img-src 'self' data:",
    "connect-src 'none'",
    "base-uri 'none'",
    "form-action 'none'",
    "frame-ancestors 'none'",
    "object-src 'none'",
  ], "; "),
  "X-Content-Type-Options" => "nosniff",
  "X-Frame-Options" => "DENY",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
  "Cross-Origin-Opener-Policy" => "same-origin",
  "Strict-Transport-Security" => "max-age=31536000",
]

reply(status, body; headers = Pair{String,String}[]) =
  HTTP.Response(status, vcat(SECURITY_HEADERS, headers), body)

struct Asset
  body::Vector{UInt8}
  gz::Union{Nothing,Vector{UInt8}}   # pre-compressed copy, if the build made one
  headers::Vector{Pair{String,String}}
end

function load_assets()
  assets = Dict{String,Asset}()
  for (dir, _, files) in walkdir(PUBLIC), f in files
    endswith(f, ".gz") && continue
    path = joinpath(dir, f)
    url = "/" * replace(relpath(path, PUBLIC), '\\' => '/')
    ext = lowercase(splitext(f)[2])
    isimage = startswith(get(CONTENT_TYPES, ext, ""), "image/")
    headers = [
      "Content-Type" => get(CONTENT_TYPES, ext, "application/octet-stream"),
      # Images never change under the same name: cache for a year.
      # The page itself is cached briefly so edits show up quickly.
      "Cache-Control" => isimage ? "public, max-age=31536000, immutable" : "public, max-age=300",
    ]
    gz = isfile(path * ".gz") ? read(path * ".gz") : nothing
    asset = Asset(read(path), gz, headers)
    assets[url] = asset
    url == "/index.html" && (assets["/"] = asset)
  end
  assets
end

const ASSETS = load_assets()

accepts_gzip(req) = occursin("gzip", HTTP.header(req, "Accept-Encoding"))

function handler(req::HTTP.Request)
  # Only the path is used, and it is only ever looked up in the in-memory
  # ASSETS table, so there is no file access driven by the request
  # (no path traversal possible).
  path = try
    HTTP.URI(req.target).path
  catch
    return reply(400, "bad request")
  end

  req.method in ("GET", "HEAD") ||
    return reply(405, "method not allowed"; headers = ["Allow" => "GET, HEAD"])

  path == "/healthz" && return reply(200, "ok"; headers = ["Cache-Control" => "no-store"])

  asset = get(ASSETS, path, nothing)
  asset === nothing && return reply(404, "not found")

  if asset.gz !== nothing && accepts_gzip(req)
    return reply(200, asset.gz;
      headers = vcat(asset.headers, ["Content-Encoding" => "gzip", "Vary" => "Accept-Encoding"]))
  end
  return reply(200, asset.body; headers = asset.headers)
end

# Julia's GC rarely hands memory back to the OS on its own. Every few minutes,
# run a full GC and ask glibc to release free pages, so the idle footprint
# stays near the baseline instead of ratcheting up after traffic bursts.
@async while true
  sleep(300)
  try
    GC.gc(true)
    ccall(:malloc_trim, Cint, (Cint,), 0)
  catch
  end
end

println("Starting HTTP.jl on 0.0.0.0:$PORT with $(length(ASSETS)) assets")
flush(stdout)

HTTP.serve(handler, "0.0.0.0", PORT)
