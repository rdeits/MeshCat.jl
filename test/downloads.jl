@testset "download helpers" begin
    url = "https://github.com/rdeits/meshcat/archive/18028760b377c178bc77ee61cf4b9de8d176d3c5.zip"
    mktempdir() do tmpdir
        target = joinpath(tmpdir, "meshcat.zip")
        run(MeshCat.DownloadHelpers.download_cmd(url, target))
        run(MeshCat.DownloadHelpers.unpack_cmd(target, tmpdir, ".zip", nothing))
    end
end
