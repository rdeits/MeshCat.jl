module ElectronExt

import MeshCat
import Electron

function Base.open(core::MeshCat.CoreVisualizer, w::Electron.Application)
    Electron.Window(w, Electron.URI(MeshCat.url(core)))
    w
end

end
