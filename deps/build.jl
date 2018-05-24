using Base.LibGit2: @check, GitRepo, CheckoutOptions, FetchOptions,
                    @kwdef, AbstractCredentials, RemoteCallbacks, credentials_cb

@kwdef struct SubmoduleUpdateOptions
    version::Cuint = 1
    checkout_opts::CheckoutOptions = CheckoutOptions()
    fetch_opts::FetchOptions
    allow_fetch::Cint = 1
end

const submodule_path = "assets/meshcat"

# Update the git submodule in `assets/meshcat`
repo = GitRepo(joinpath(@__DIR__, ".."))
submodule_ptr_ptr = Ref{Ptr{Void}}(C_NULL)
@check ccall((:git_submodule_lookup, :libgit2), Cint, (Ptr{Ptr{Void}}, Ptr{Void}, Cstring), submodule_ptr_ptr, repo.ptr, submodule_path)

function submodule_update(submodule_ptr::Ptr{Void}, payload::Nullable{<:AbstractCredentials}=Nullable{AbstractCredentials}())
    options = SubmoduleUpdateOptions(
        fetch_opts=FetchOptions(callbacks=RemoteCallbacks(credentials_cb(), Ref(payload))),
        )
    # @check ccall((:git_submodule_init, :libgit2), Cint, (Ptr{Void}, Cint), submodule_ptr, 0)
    @check ccall((:git_submodule_update, :libgit2),
                 Cint,
                 (Ptr{Void}, Cint, Ptr{Void}),
                 submodule_ptr, 1, Ref(options))
end

submodule_update(submodule_ptr_ptr[])

ccall((:git_submodule_free, :libgit2), Void, (Ptr{Void},), submodule_ptr_ptr[])

## Previous method, which relied on the user having the `git` executable
## on their path:
# run(`git submodule update --init --recursive`)
