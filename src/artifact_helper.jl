using Tar, Inflate, SHA

function artifact_helper(sha::AbstractString)
    url = "https://github.com/rdeits/meshcat/tarball/$sha"
    filename = download(url)

    println("""
[meshcat]
git-tree-sha1 = "$(Tar.tree_hash(IOBuffer(inflate_gzip(filename))))"

    [[meshcat.download]]
    url = "$url"
    sha256 = "$(bytes2hex(open(sha256, filename)))"
""")
end
