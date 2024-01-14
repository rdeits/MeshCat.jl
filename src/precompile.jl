import PrecompileTools

PrecompileTools.@compile_workload begin
    vis = Visualizer()
    close_server!(vis.core)
end
