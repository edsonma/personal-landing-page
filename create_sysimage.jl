# Bakes a custom Julia sysimage with Genie (and its dependency tree)
# precompiled in. This is what actually fixes slow cold-boot on
# fly.io — without it, every container start pays Julia's full
# "using Genie" JIT cost (often 60-120s+), which is what was
# causing the proxy's "instance refused connection" timeouts.
using PackageCompiler

create_sysimage(
    ["Genie"];
    sysimage_path = "GenieSysimage.so",
    project = "."
)
