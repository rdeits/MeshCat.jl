module ElectronExt

import MeshCat
import Electron

function Base.open(core::MeshCat.CoreVisualizer, w::Electron.Application; kwargs...)
    Electron.Window(w, Electron.URI(MeshCat.url(core)); kwargs...)
    w
end

end
