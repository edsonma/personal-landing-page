# Bakes Genie (and its full dependency tree) into a custom sysimage.
# Confirmed via manual boot testing that plain `using Genie` takes
# several minutes of real CPU-bound compilation on a shared vCPU —
# this is what actually fixes that, by doing the compilation once
# at build time instead of on every cold boot.
using PackageCompiler

create_sysimage(
    ["Genie"];
    sysimage_path = "GenieSysimage.so",
    project = "."
)
