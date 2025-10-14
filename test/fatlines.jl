import CoordinateTransformations: Point, Translation
import MeshCat: threejs_type

@testset "FatLines" begin
    vis = Visualizer()

    @testset "FatLineGeometry construction" begin
        # Basic construction with points
        points = [Point(0, 0, 0), Point(1, 0, 0), Point(1, 1, 0)]
        geom = FatLineGeometry(points)
        @test length(geom.position) == 3
        @test isempty(geom.color)

        # Construction with colors
        colors = [RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1)]
        geom_colored = FatLineGeometry(points, colors)
        @test length(geom_colored.position) == 3
        @test length(geom_colored.color) == 3
    end

    @testset "FatLineMaterial construction" begin
        # Default material
        mat = FatLineMaterial()
        @test mat.linewidth == 1.0
        @test mat.vertexColors == false
        @test mat.dashed == false

        # Custom material
        mat_custom = FatLineMaterial(
            color=RGB(1, 0, 0),
            linewidth=5.0,
            vertexColors=true
        )
        @test mat_custom.linewidth == 5.0
        @test mat_custom.vertexColors == true
        @test mat_custom.color == RGBA{Float32}(1, 0, 0, 1)

        # Dashed material
        mat_dashed = FatLineMaterial(
            dashed=true,
            dashScale=2.0,
            dashSize=3.0,
            gapSize=1.0
        )
        @test mat_dashed.dashed == true
        @test mat_dashed.dashScale == 2.0
        @test mat_dashed.dashSize == 3.0
        @test mat_dashed.gapSize == 1.0
    end

    @testset "FatLine object creation" begin
        points = [Point(0, 0, 0), Point(1, 0, 0), Point(1, 1, 0)]

        # From points with default material
        line1 = FatLine(points)
        @test line1 isa Object
        @test threejs_type(line1) == "Line2"

        # From points with custom material
        mat = FatLineMaterial(linewidth=10.0, color=RGB(1, 0, 0))
        line2 = FatLine(points, mat)
        @test line2 isa Object
        @test MeshCat.material(line2).linewidth == 10.0

        # From geometry and material
        geom = FatLineGeometry(points)
        line3 = FatLine(geom, mat)
        @test line3 isa Object
        @test MeshCat.geometry(line3) == geom
        @test MeshCat.material(line3) == mat
    end

    @testset "FatLine visualization" begin
        v = vis[:fatlines]
        delete!(v)

        # Simple fat line
        points = [Point(0, 0, 0), Point(1, 0, 0), Point(1, 1, 0), Point(0, 1, 0)]
        setobject!(v[:simple], FatLine(points, FatLineMaterial(linewidth=5.0, color=RGB(1, 0, 0))))

        # Fat line with vertex colors
        colors = [RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1), RGB(1, 1, 0)]
        geom = FatLineGeometry(points, colors)
        mat = FatLineMaterial(linewidth=8.0, vertexColors=true)
        setobject!(v[:colored], FatLine(geom, mat))
        settransform!(v[:colored], Translation(0, 0, 0.5))

        # Dashed fat line
        setobject!(v[:dashed],
            FatLine(points,
                FatLineMaterial(
                    linewidth=3.0,
                    color=RGB(0, 1, 1),
                    dashed=true,
                    dashSize=0.1,
                    gapSize=0.05
                )))
        settransform!(v[:dashed], Translation(0, 0, 1.0))
    end

    @testset "FatLine lowering" begin
        points = [Point(0, 0, 0), Point(1, 0, 0), Point(1, 1, 0)]
        colors = [RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1)]

        # Test geometry lowering
        geom = FatLineGeometry(points)
        lowered_geom = MeshCat.lower(geom)
        @test lowered_geom["type"] == "LineGeometry"
        @test haskey(lowered_geom, "uuid")
        @test haskey(lowered_geom, "position")
        @test haskey(lowered_geom["position"], "array")

        # Test geometry lowering with colors
        geom_colored = FatLineGeometry(points, colors)
        lowered_geom_colored = MeshCat.lower(geom_colored)
        @test haskey(lowered_geom_colored, "color")
        @test haskey(lowered_geom_colored["color"], "array")

        # Test material lowering
        mat = FatLineMaterial(linewidth=10.0, color=RGB(1, 0, 0))
        lowered_mat = MeshCat.lower(mat)
        @test lowered_mat["type"] == "LineMaterial"
        @test lowered_mat["linewidth"] == 10.0
        @test lowered_mat["vertexColors"] == false

        # Test dashed material lowering
        mat_dashed = FatLineMaterial(dashed=true, dashScale=2.0, dashSize=3.0, gapSize=1.0)
        lowered_mat_dashed = MeshCat.lower(mat_dashed)
        @test lowered_mat_dashed["dashed"] == true
        @test lowered_mat_dashed["dashScale"] == 2.0
        @test lowered_mat_dashed["dashSize"] == 3.0
        @test lowered_mat_dashed["gapSize"] == 1.0

        # Test worldUnits material lowering
        mat_world = FatLineMaterial(worldUnits=true)
        lowered_mat_world = MeshCat.lower(mat_world)
        @test lowered_mat_world["worldUnits"] == true

        mat_pixel = FatLineMaterial(worldUnits=false)
        lowered_mat_pixel = MeshCat.lower(mat_pixel)
        @test lowered_mat_pixel["worldUnits"] == false
    end
end
