# Update the git submodule in `assets/meshcat`

using Base.LibGit2: @check, GitRepo, CheckoutOptions, FetchOptions,
                    @kwdef, AbstractCredentials, RemoteCallbacks, credentials_cb

@kwdef struct SubmoduleUpdateOptions
    version::Cuint = 1
    checkout_opts::CheckoutOptions = CheckoutOptions()
    fetch_opts::FetchOptions
    allow_fetch::Cint = 1
end

const submodule_path = "assets/meshcat"

try
    repo = GitRepo(joinpath(@__DIR__, ".."))
    submodule_ptr_ptr = Ref{Ptr{Void}}(C_NULL)

    @check ccall((:git_submodule_lookup, :libgit2), Cint, (Ptr{Ptr{Void}}, Ptr{Void}, Cstring), submodule_ptr_ptr, repo.ptr, submodule_path)
    payload = Nullable{AbstractCredentials}()
    options = SubmoduleUpdateOptions(fetch_opts=FetchOptions(callbacks=RemoteCallbacks(credentials_cb(), Ref(payload))))
    @check ccall((:git_submodule_update, :libgit2),
                 Cint,
                 (Ptr{Void}, Cint, Ptr{Void}),
                 submodule_ptr_ptr[], 1, Ref(options))

    ccall((:git_submodule_free, :libgit2), Void, (Ptr{Void},), submodule_ptr_ptr[])
catch e
    warn("Using LibGit2 to update the meshcat submodule failed. Please report this issue at https://github.com/rdeits/MeshCat.jl/issues")
    warn("LibGit2 error was: $e")
    info("Falling back to command-line git")

    run(`git submodule update --init --recursive`)
end
