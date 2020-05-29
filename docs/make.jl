using Documenter
using MeshCat

makedocs(
    sitename = "MeshCat",
    format = Documenter.HTML(),
    modules = [MeshCat]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
