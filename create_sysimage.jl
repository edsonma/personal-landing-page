# Bakes Genie (and its full dependency tree) into a custom sysimage.
# Confirmed via manual boot testing that plain `using Genie` takes
# several minutes of real CPU-bound compilation on a shared vCPU —
# this is what actually fixes that, by doing the compilation once
# at build time instead of on every cold boot.
using PackageCompiler

create_sysimage(
    ["Genie"];
    sysimage_path = "GenieSysimage.so",
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
