# Bakes HTTP.jl (and its dependency tree) into a custom sysimage, so the
# server boots in seconds instead of compiling on every cold start.
using PackageCompiler

create_sysimage(
    ["HTTP"];
    sysimage_path = "AppSysimage.so",
    project = ".",
    # IMPORTANT: build and runtime containers can land on different
    # physical CPUs on cloud platforms (seen on Railway: sysimage
    # built against znver3-specific features, then rejected at
    # runtime on a host without them — "Unable to find compatible
    # target in cached code image"). "generic" avoids baking in any
    # CPU-specific instruction set, trading a little performance for
    # running correctly on whatever hardware the platform assigns.
    cpu_target = "generic"
)
