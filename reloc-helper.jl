#!/usr/bin/env julia
using TOML
using Pkg

if any(startswith("--help"), ARGS) || any(startswith("-h"), ARGS)
    # Description written by AI
    println("""
Julia Package Relocatability Test Script v0.1.0

DESCRIPTION:
    This script tests whether a Julia package can be relocated (moved) to a different
    directory while maintaining its functionality. It creates a temporary depot,
    develops the package, precompiles it, tests it, then moves the depot to a new
    location and tests again to verify relocatability.

USAGE:
    ./reloc-helper.jl PACKAGE [SUBDIR]
    ./reloc-helper.jl --help
    ./reloc-helper.jl -h

ARGUMENTS:
    PACKAGE     Either a package name (for registered packages) or a local path
                to a package directory. If it contains '/', '.' or '\\\\', it's treated
                as a local path.
    
    SUBDIR      Optional subdirectory within the package path (only used when
                PACKAGE is a local path). Useful for monorepos with multiple
                packages.

OPTIONS:
    -h, --help  Show this help message and exit

EXAMPLES:
    # Test a registered package
    ./reloc-helper.jl JSON

    # Test a local package
    ./reloc-helper.jl /path/to/MyPackage

    # Test a package in a subdirectory of a monorepo
    ./reloc-helper.jl /path/to/monorepo MySubPackage

BEHAVIOR:
    1. Creates a temporary directory as scratch space
    2. Sets up a Julia depot in scratch/build
    3. Develops the specified package in the depot
    4. Precompiles and tests the package
    5. Patches the manifest to use relative paths
    6. Moves the depot to scratch/host (simulating relocation)
    7. Tests the package again to verify it still works after relocation

EXIT CODES:
    0   Success - package may be relocatable
    1   Failure - package failed tests or is not relocatable
    """)
    exit(0)
end


scratch = mktempdir()
@info "using $(repr(scratch)) as a scratch space"
depot1 = joinpath(scratch, "build")
dev_dir = joinpath(depot1, "dev")
julia_failed::Bool = false

function run_julia(code, depot)
    cmd = `$(joinpath(Sys.BINDIR, Base.julia_exename())) --check-bounds=yes -e $(code)`
    added_env = Dict("JULIA_DEPOT_PATH"=> depot*":", "JULIA_PKG_DEVDIR"=> nothing)
    @info "running $(repr(cmd)) with env $(added_env)"
    try
        run(addenv(cmd, added_env))
    catch e
        # If the process failed, don't error out
        # right now, because it will prevent any relocation errors
        # from being seen
        e isa ProcessFailedException|| rethrow()
        global julia_failed = true
        display(e)
    end
end


target_package = if contains(ARGS[1], "/") || contains(ARGS[1], ".") || contains(ARGS[1], "\\")
    @info "assuming target package is a local path, copying the package"
    target_path = rstrip(abspath(ARGS[1]), ['/', '\\'])
    @show target_path
    mkpath(dev_dir)
    target_path = cp(target_path, joinpath(dev_dir, basename(target_path)))
    prjdir = if length(ARGS) == 2
        joinpath(target_path, ARGS[2])
    else
        target_path
    end
    prjn = if isfile(joinpath(prjdir, "JuliaProject.toml"))
        TOML.parsefile(joinpath(prjdir, "JuliaProject.toml"))["name"]
    else
        TOML.parsefile(joinpath(prjdir, "Project.toml"))["name"]
    end
    run_julia("""
        using Pkg
        Pkg.activate("myenv"; shared=true)
        Pkg.develop(path=$(repr(prjdir)))
        Pkg.precompile()
    """, depot1)
    prjn
else
    run_julia("""
        using Pkg
        Pkg.activate("myenv"; shared=true)
        Pkg.develop($(repr(ARGS[1])))
        Pkg.precompile()
    """, depot1)
    ARGS[1]
end

# patch manifest to use relative paths to "dev"
env_manifest_path = joinpath(depot1, "environments/myenv/Manifest.toml")
manifest = TOML.parsefile(env_manifest_path)
env_dev_path = manifest["deps"][target_package][1]["path"]
if isabspath(env_dev_path)
    env_rel_path = relpath(env_dev_path, dirname(env_manifest_path))
    @info "changing path in $(repr(env_manifest_path)) from $(repr(env_dev_path)) to $(repr(env_rel_path))"
    manifest["deps"][target_package][1]["path"] = env_rel_path
    write(env_manifest_path, sprint(io-> TOML.print(io, manifest)))
end

# test the package
run_julia("""
    using Pkg
    Pkg.activate("myenv"; shared=true)
    pkg = Base.identify_package($(repr(target_package)))
    @show Base.isprecompiled(pkg)
    @show Base.isrelocatable(pkg)
    Pkg.test($(repr(target_package)))
""", depot1)

depot2 = joinpath(scratch, "host")
@info "moving depot from $(repr(depot1)) to $(repr(depot2))"
mv(depot1, depot2)

# test the package again
run_julia("""
    using Pkg
    Pkg.activate("myenv"; shared=true)
    pkg = Base.identify_package($(repr(target_package)))
    @show Base.isprecompiled(pkg)
    @show Base.isrelocatable(pkg)
    Pkg.test($(repr(target_package)))
""", depot2)

if julia_failed
    exit(1)
end
