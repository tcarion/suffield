using Plots

include("read_sensors.jl")
include("read_recept.jl")

run_name = "NH3_190821"
run_name = "NH3"
fppath = joinpath("flexpart_outputs", run_name)

fpdir = FlexpartDir(fppath)

receptor = read_receptor(fpdir)
sensor = read_sensors()

begin
    plot(receptor.time, receptor.ppv,
        xlim = (sensor.time[1], sensor.time[end]),
        marker = :dot
    )
    plot!(sensor.time, sensor.ppm * 1000000)
end

stack = RasterStack(OutputFiles(fpdir)[1].path)
spec001_mr = stack[:spec001_mr] 
DateTime(2014, 8, 18, 19) .+ Second.(collect(stack[:RELSTART]))
stack[:RELPART] |> collect
plot(
    view(spec001_mr,
        Dim{:height}(At(2.0)),
        Dim{:pointspec}(1),
        Dim{:nageclass}(1),
        Ti(Near(DateTime(2014, 8, 19, 3, 15))),
    )
)