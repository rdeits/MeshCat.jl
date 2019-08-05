module UtilTest

using Test
using Random
using MeshCat: mergesorted!

@testset "mergesorted!" begin
    @testset "basic" begin
        rng = MersenneTwister(1)
        for i = 1 : 1000
            a = sort(rand(1 : 100, rand(0 : 20)))
            b = sort(rand(1 : 100, rand(0 : 20)))
            result = similar(a, length(a) + length(b))
            mergesorted!(result, a, b)
            @test issorted(result)
            @test a ⊆ result
            @test b ⊆ result
        end
    end

    @testset "by" begin
        rng = MersenneTwister(1)
        for i = 1 : 1000
            a = sort([rand(1 : 100) => rand(1 : 100) for _ in rand(0 : 20)]; dims=1, by=first)
            b = sort([rand(1 : 100) => rand(1 : 100) for _ in rand(0 : 20)]; dims=1, by=first)
            result = similar(a, length(a) + length(b))
            mergesorted!(result, a, b; by=first)
            @test issorted(result; by=first)
            @test a ⊆ result
            @test b ⊆ result
        end
    end
end

end
