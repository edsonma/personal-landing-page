using Genie

Genie.Configuration.config!(
  server_port                    = parse(Int, get(ENV, "PORT", "8000")),
  server_host                    = "0.0.0.0",
  log_level                      = Base.CoreLogging.Info,
  log_to_file                    = false,
  server_handle_static_files     = true,
  path_build                     = "build",
)
