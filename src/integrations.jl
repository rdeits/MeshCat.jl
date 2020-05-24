function setup_integrations()
    @require Blink="ad839575-38b3-5650-b840-f874b8c74a25" begin
        function Base.open(core::CoreVisualizer, w::Blink.AtomShell.Window)
            # Ensure the window is ready
            Blink.wait(w)
            # Set its contents
            Blink.loadurl(w, url(core))
            w
        end
    end

    @require WebIO="0f1e0344-ec1d-5b48-a673-e5cf874b6c29" begin
        WebIO.render(vis::Visualizer) = WebIO.render(vis.core)

        WebIO.render(core::CoreVisualizer) = WebIO.render(MeshCat.render(core))
    end
end
