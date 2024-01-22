using Tar, Inflate, SHA

function artifact_helper(sha::AbstractString)
    url = "https://github.com/meshcat-dev/meshcat/tarball/$sha"
    filename = download(url)

    links = tar_get_symlinks(filename)
    isempty(links) || error("symlinks not supported on Windows. Found $(links)")

    println("""
[meshcat]
git-tree-sha1 = "$(Tar.tree_hash(IOBuffer(inflate_gzip(filename))))"

    [[meshcat.download]]
    url = "$url"
    sha256 = "$(bytes2hex(open(sha256, filename)))"
""")
end

function tar_get_symlinks(filename::AbstractString)
    symlinks_output = Pair{String,String}[]
    Tar.list(IOBuffer(inflate_gzip(filename))) do header::Tar.Header
        if (header.type == :symlink)
            push!(symlinks_output, header.path=>header.link)
        end
        nothing
    end
    symlinks_output
end