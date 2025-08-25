module WebIOExt

import MeshCat
import WebIO

WebIO.render(vis::MeshCat.Visualizer) = WebIO.render(vis.core)

WebIO.render(core::MeshCat.CoreVisualizer) = WebIO.render(MeshCat.render(core))

end
