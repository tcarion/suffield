using Flexpart
using Rasters
using Dates
using FlexPlot
using WGLMakie
using JSServe

using GLMakie
using CairoMakie

ENV["http_proxy"] = ""
ENV["https_proxy"] = ""

function myplot(gp, mr; kw...)
    _, pl = flexpartplot(gp[1, 1], mr; kw...)
    Colorbar(gp[1, 2], pl.plots[1], width = 25, ticksize=25,
        labelsize=18,
        ticklabelsize = 18,tickalign = 1, minortickalign =1,
        height = Relative(0.87),
		minorticksvisible=false,
        tickformat= kw[:scale] == :log10 ? custom_formatter : Makie.automatic,
		minorticks= kw[:scale] == :log10 ? LogMinorTicks() : IntervalsBetween(5),
        )
end

ch4_output = DeterministicOutput("grid_conc_20140811000000_nest_CH4.nc")
satfile = "2021-06-29-00 00_2021-06-29-23 59_Landsat_8_L2_True_color_low_8bit.tiff"

ch4_mr = MixingRatio(ch4_output)
sat = GeoTiff(satfile)

ch4_raster = RasterStack(ch4_output)
ch4_raster[:RELZZ1][:]
ch4_raster[:RELSTART][:]
ch4_raster[:RELPART][:] |> sum
comment = reduce(*, stack[:RELCOM][:, 1] |> collect)
ch4_raster.metadata

spec_ch4 = ch4_raster[:spec001_mr]

f = Figure(resolution = (1000, 700))
ax = f[1, 1] = Axis(f)

filtered = view(ch4_mr.raster,
    # Y(Between(50., 50.5)),
    # X(Between(-110.5, -111.)),
    Dim{:height}(1),
    Dim{:pointspec}(1),
    Dim{:nageclass}(1),
    Ti(At(DateTime(2014, 08, 11, 23, 30)))
)

raster = view(ch4_mr.raster,
    # Y(Between(50., 50.5)),
    # X(Between(-110.5, -111.)),
    # Dim{:height}(1),
    Dim{:pointspec}(1),
    Dim{:nageclass}(1),
    Ti(Between(DateTime(2014, 08, 11, 22, 30), DateTime(2014, 08, 12, 3, 00)))
)

raster = view(ch4_mr.raster,
    # Y(Between(50., 50.5)),
    # X(Between(-110.5, -111.)),
    # Dim{:height}(1),
    Dim{:pointspec}(1),
    Dim{:nageclass}(1),
    Ti(Between(DateTime(2014, 08, 11, 22, 30), DateTime(2014, 08, 12, 3, 00)))
)

myplot(ax, ch4_mr, 
    time=Ti(2), 
    lons = X(Between(2, 8)), 
    lats = Y(Between(50, 52)),
    scale = :lin,
    title = "dsqdqsd"
)
contourf(dims(filtered, :X) |> collect, dims(filtered, :Y) |> collect, replace(x -> isapprox(x, 0.) ? NaN : x, filtered |> Matrix))
# contourf(filtered, levels= 0.1:0.1:1, mode = :relative)
contourf(replace(x -> isapprox(x, 0.) ? NaN : x, filtered))
heatmap(replace(x -> isapprox(x, 0.) ? NaN : x, filtered))

satzoom = sat.raster[:, :];
satzoom = sat.raster[1:15, 1:15];
heatmap(sat.raster)
f = GLMakie.heatmap(dims(satzoom, :X) |> collect, dims(satzoom, :Y) |> collect, Matrix(satzoom))
display(f)
m = Matrix(satzoom)

obsconc = Observable(replace(x -> isapprox(x, 0.) ? NaN : x, filtered))

obsconc[] = replace(x -> isapprox(x, 0.) ? NaN : x, filtered)
f = Figure();
ax, hm = heatmap(f[1, 1], sat.raster);
chm = heatmap!(ax, obsconc)
relpoints = [scatter!(ax, p[end:-1:1]; marker = :star4, color = :red, markersize = 30) for p in ch4_mr.relpoints]
relpoints = [p[end:-1:1] for p in ch4_mr.relpoints]
deleteat!(f.scene.children[1].plots, length(f.scene.children[1].plots))
app = App() do session::Session
    # ax, hm = heatmap(f[1, 1], rand(3, 3))
    return DOM.div(f)
end;

server = JSServe.Server(app, "127.0.0.1", 8080);
isdefined(Main, :server) && close(server)


flexpartplot!(ax, ch4_mr, time = Ti(At(DateTime(2014, 08, 11, 23, 00))))
f = sliderplot(raster)
loadedrast = read(raster)
replace!(x -> isapprox(x, 0.) ? NaN : x, loadedrast)
f = sliderplot(loadedrast)
f = sliderplot(loadedrast, sat)
f = FlexPlot.sliderplot2(loadedrast, sat)
translate!(contents(f[2, 1])[1].scene.plots[3], 0, 0, 0)

scatter!(f.current_axis[], (ch4_mr.relpoints[1][1], ch4_mr.relpoints[1][2]); marker = :star4, color = :red, markersize = 30)

getndims(r::Raster{T, N}) where {T, N} = N

vertconc = view(ch4_mr.raster,
    Y(Near(50.25,)),
    X(Near(-110.8)),
    # Dim{:height}(1),
    Dim{:pointspec}(1),
    Dim{:nageclass}(1),
    Ti(At(DateTime(2014, 08, 11, 22, 45)))
)

fvert = Figure()
axvert = Axis(fvert[1, 1],
    xlabel = "concentration [ng/m3]",    
    ylabel = "height [m]",
)
scatterlines!(axvert, vertconc |> collect, dims(vertconc, Dim{:height}()) |> collect,)
# randm = reshape([rand(ColorTypes.RGB{Float32}) for i in 1:100], (10, 10))
# randm = reshape([rand(RGB{N0f8}) for i in 1:100], (10, 10))
# randm = reshape([rand(RGB) for i in 1:100], (10, 10))
# randmn0 = ColorTypes.N0f8.(randm)
# heatmap(randm)
# rgb = rand(ColorTypes.RGB{Float32})
# n0f8 = convert(ColorTypes.N0f8, rgb)
tiff = sat
time = Observable(DateTime(2014, 08, 11, 22, 30))

timestamps = DateTime(2014, 08, 11, 22, 30):Dates.Minute(15):DateTime(2014, 08, 12, 1, 00)

filtered = @lift(replace(x -> isapprox(x, 0.) ? NaN : x, Matrix(view(ch4_mr.raster,
    # Y(Between(50., 50.5)),
    # X(Between(-110.5, -111.)),
    Dim{:height}(1),
    Dim{:pointspec}(1),
    Dim{:nageclass}(1),
    Ti(At($time))
))))

fig = Figure()
ax = Axis(fig[1, 1], 
    title =  @lift("CH4 - $(dims(ch4_mr.raster, :height)[1])m - $(Dates.format($time, "yyyy-mm-ddTHH:MM"))"),
    )
hmtiff = image!(ax, dims(tiff.raster, :X) |> collect, dims(tiff.raster, :Y) |> collect, tiff.raster |> Matrix)
hm = heatmap!(ax, dims(ch4_mr.raster, :X) |> collect, dims(ch4_mr.raster, :Y) |> collect, filtered, colormap = (:viridis, 0.8))
col = Colorbar(fig[1, 2], hm, 
    label = "ng/m^3",
    tickformat = "{:.2e}"
    )
scatter!(ax, (ch4_mr.relpoints[1][1], ch4_mr.relpoints[1][2]); marker = :star4, color = :red, markersize = 30)

framerate = 1

record(fig, "time_animation.gif", timestamps;
        framerate = framerate) do t
    time[] = t
end

