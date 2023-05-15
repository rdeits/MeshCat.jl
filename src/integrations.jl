function setup_integrations()
    @require Electron="a1bb12fb-d4d1-54b4-b10a-ee7951ef7ad3" begin
        function Base.open(core::CoreVisualizer, w::Electron.Application)
            Electron.Window(w, Electron.URI(url(core)))
            w
        end
    end

    @require WebIO="0f1e0344-ec1d-5b48-a673-e5cf874b6c29" begin
        WebIO.render(vis::Visualizer) = WebIO.render(vis.core)

        WebIO.render(core::CoreVisualizer) = WebIO.render(MeshCat.render(core))
    end
end
