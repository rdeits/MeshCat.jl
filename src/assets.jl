"""
Use git to clone the meshcat javascript assets repository for local development.

$(SIGNATURES)

You should only do this if you plan on editing the javascript or HTML components of
meshcat itself. To undo this operation, you will need to delete the `assets/meshcat`
folder and then run `using Pkg; Pkg.build("MeshCat")`
"""
function develop_meshcat_assets(skip_confirmation=false)
    meshcat_dir = abspath(joinpath(@__DIR__, "..", "assets", "meshcat"))
    if !skip_confirmation
        println("CAUTION: This will delete all downloaded meshcat assets and replace them with a git clone.")
        println("The following path will be overwritten:")
        println(meshcat_dir)
        println("To undo this operation, you will need to manually remove that directory and then run `Pkg.build(\"MeshCat\")`")
        print("Proceed? (y/n) ")
        choice = chomp(readline())
        if isempty(choice) || lowercase(choice[1]) != 'y'
            println("Canceled.")
            return
        end
    end
    println("Removing $meshcat_dir")
    rm(meshcat_dir, force=true, recursive=true)
    run(`git clone https://github.com/meshcat-dev/meshcat $meshcat_dir`)
    rm(joinpath(meshcat_dir, "..", "meshcat.stamp"))
end
