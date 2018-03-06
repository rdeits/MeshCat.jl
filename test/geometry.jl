@testset "geometry" begin
    l = 1.0
    r = 2.0
    c = HyperCylinder(l, r)
    @test length(c) == l
    @test radius(c) == r

end