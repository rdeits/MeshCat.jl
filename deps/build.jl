using Base.LibGit2: @check, GitRepo

const submodule_path = "assets/meshcat"

# Update the git submodule in `assets/meshcat`
repo = LibGit2.GitRepo(joinpath(@__DIR__, ".."))
submodule_ptr_ptr = Ref{Ptr{Void}}(C_NULL)
@check ccall((:git_submodule_lookup, :libgit2), Cint, (Ptr{Ptr{Void}}, Ptr{Void}, Cstring), submodule_ptr_ptr, repo.ptr, submodule_path)
@check ccall((:git_submodule_update, :libgit2), Cint, (Ptr{Void}, Cint, Ptr{Void}), submodule_ptr_ptr[], 1, C_NULL)
ccall((:git_submodule_free, :libgit2), Void, (Ptr{Void},), submodule_ptr_ptr[])

## Previous method, which relied on the user having the `git` executable
## on their path:
# run(`git submodule update --init --recursive`)
