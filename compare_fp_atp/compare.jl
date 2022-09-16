using ATP45
using GRIBDatasets
using DimensionalData
using Rasters
using Dates
using GLMakie
using CairoMakie
using MakieCore: @recipe
using MakieCore
using GeoJSON
using ArchGDAL
### Parameters

const AG = ArchGDAL

fpoutputfile = "/home/tcarion/Documents/suffield/postprocess/flexpart_outputs/NH3_132150_140000_ctl10_500m/output/grid_conc_20140813215400.nc"
inputfile = "/home/tcarion/Documents/suffield/postprocess/inputs/ENH14081321"


### Methods and struct definitions

struct FpOutput
    stack::AbstractRasterStack
    metadata::NamedTuple
end

function FpOutput(file::String)
    stack = RasterStack(file)
    released_mass = first(stack[:RELXMASS]|>collect)
    sim_start = DateTime(stack.metadata[:ibdate]*"T"*stack.metadata[:ibtime], "yyyymmddTHHMMSS")
    release_start = first(Second.(stack[:RELSTART]|>collect) .+ sim_start)
    getrelloc = x -> first(unique(x))
	relloc = (lon=stack[:RELLNG1] |> getrelloc, lat=stack[:RELLAT1] |> getrelloc)
    meta = (
        released_mass = released_mass,
        sim_start = sim_start,
        release_start = release_start,
        relloc = relloc
    )
    FpOutput(stack, meta)
end
Base.show(io::IO, m::MIME"text/plain", o::FpOutput) = show(io, m, o.stack)
Base.view(out::FpOutput; kwargs...) = view(out.stack[:spec001_mr]; nageclass = 1, kwargs...)

struct Input
    u10::AbstractArray
    v10::AbstractArray
end

function Input(file::String)
    input_ds = GRIBDataset(file)
    lons = input_ds["longitude"][:] .- 360
	lats = input_ds["latitude"][:]
	u10_raw = input_ds["u10"]
	v10_raw = input_ds["v10"]
    u10 = DimArray(u10_raw[:,:,1,1], (X = lons, Y = lats))
	v10 = DimArray(v10_raw[:,:,1,1], (X = lons, Y = lats))
    Input(u10, v10)
end


function ATP45.WindVector(input::Input, lon, lat)
    near_u = input.u10[X(Near(lon)), Y(Near(lat))]
	near_v = input.v10[X(Near(lon)), Y(Near(lat))]
	ATP45.WindVector(near_u * 3.6, near_v * 3.6)
end
ATP45.WindVector(input::Input, fpout::FpOutput) = ATP45.WindVector(input, fpout.metadata.relloc.lon, fpout.metadata.relloc.lat)

function ATP45.Atp45Result(wind::ATP45.AbstractWind, fpout::FpOutput)
    atpinput = Atp45Input(
        [convert(Array{Float64}, collect(fpout.metadata.relloc))],
        wind,
        :BOM,
        :simplified,
        ATP45.Stable
    )
    run_chem(atpinput)
end

### Recipes

@recipe(AtpPlot, result) do scene
    Theme(
        plot_color = :black
    )
end

function MakieCore.plot!(myplot::AtpPlot)
    result = myplot[:result].val
    for coll in result.collection
        coords = GeoJSON.coordinates(coll)[1]
        tuple = Tuple.(push!(copy(coords), coords[1]))
        lines!(myplot, tuple, color = myplot[:plot_color])
    end

    for loc in result.input.locations
        MakieCore.scatter!(myplot, [Tuple(loc)], color = :red)
    end
    # line(ATP45.GeoJSON.coordinates(result.collection))
    myplot
end

@recipe(Footprint, conc) do scene
    Theme(
        # plot_color = :red
        plot_color = :red,
        plot_linewidth = 2,
        plot_linestyle = nothing,
        thres = 0.1,
        rel_start = now()
    )
end

function MakieCore.plot!(myplot::Footprint)
    conc = myplot[:conc].val
    trimed = trim(conc)
    x = dims(conc, :X) |> collect
    y = dims(conc, :Y) |> collect
    maxconc = maximum(conc)
    level = maxconc * myplot[:thres].val
    GLMakie.contour!(myplot, x, y, trimed |> Matrix,
        linewidth = myplot[:plot_linewidth], 
        color = myplot[:plot_color],
        linestyle = myplot[:plot_linestyle],
        levels = [level],
    )
    myplot
end

@recipe(ConcHeat, conc) do scene
    Theme()
end

function MakieCore.plot!(myplot::ConcHeat)
    conc = myplot[:conc].val
    miss_conc = replace(conc, 0. => missing)
    heatmap!(myplot, dims(miss_conc, :X) |> collect, dims(miss_conc, :Y) |> collect, Matrix(miss_conc))

end

### Objects creation

fpoutput = FpOutput(fpoutputfile)
input = Input(inputfile)
nearest = WindVector(input, fpoutput)

atp_result = ATP45.Atp45Result(nearest, fpoutput)

conc_ts = view(fpoutput,
    height = 2,
    pointspec = 1,
)
times = dims(conc_ts, Ti) |> collect
times_after_release = _min_since_rel.(times, fpoutput.metadata.release_start)
hazard_area = feat2polygon(atp_result.collection[2])

@time overlap = overlap_ratio(conc_ts, hazard_area)

### Plot Options
Base.@kwdef struct FootprintOptions
    time = 1
    thres = 0.1
    color = :black
    linestyle = nothing
end

footprintopts = [
    FootprintOptions(time = 3, color = :purple),
    FootprintOptions(time = 15, color = :red),
    FootprintOptions(time = 30, color = :green, thres = 0.1),
    FootprintOptions(time = 45, color = :orange, thres = 0.1),
]


### Plots
CairoMakie.activate!()
GLMakie.activate!()

#### Horizontal plot
##
set_theme!()
f = Figure(resolution = (800, 800))
ax = Axis(f[1, 1], 
    xgridvisible = false,
    ygridvisible = false,
    aspect = 1
    )
atpplot!(ax, atp_result)
# heat = concheat!(ax, conc)
# Colorbar(f[1, 2], heat.plots[1])
legs = LegendElement[]
labels = String[]
for opt in footprintopts
    dt_to_plot = fpoutput.metadata.release_start .+ Minute.(opt.time)
    conc = view(conc_ts,
        Ti(Near(dt_to_plot))
    )
    label = "$(minutes_since_release(conc, fpoutput)) min"
    plotfootprint!(current_axis(), conc;
        label = label,
        thres = opt.thres,
        color = opt.color,
        linestyle = opt.linestyle
    )
    leg = LineElement(color = opt.color, linestyle = opt.linestyle)
    push!(legs, leg)
    push!(labels, label)
end
legobj = Legend(f[1,1], 
    legs, labels,
    # patchsize = (35, 35), rowgap = 10
    tellwidth = false,
    tellheight = false,
    halign = :right,
    valign = :top,
    margin = (15, 15, 15, 15),
    labelsize = 24
    )
f
##
save("compare_fp_atp/fp_vs_atp.svg", f, pt_per_unit = 1)

function plotfootprint!(ax, conc; thres = 0.1, kwargs...)
    trimed = trim(conc)
    x = dims(conc, :X) |> collect
    y = dims(conc, :Y) |> collect
    maxconc = maximum(conc)
    level = maxconc * thres
    contour!(ax, x, y, trimed |> Matrix;
        levels = [level],
        NamedTuple(kwargs)...
    )
end

#### Overlap time series

lines(times_after_release, overlap)
save("compare_fp_atp/overlap_ratio.svg", current_figure(), pt_per_unit = 1)
### Helpers
function time_since_release(conc, fpoutput)
    difftime = first(refdims(conc, Ti)) - fpoutput.metadata.release_start
    reftime = Minute(difftime)
end

function minutes_since_release(conc, fpoutput)
    _min_since_rel(first(refdims(conc, Ti)), fpoutput.metadata.release_start)
end

function _min_since_rel(after, start)
    difftime = after - start
    Int(round(Dates.value(difftime) / 1000 / 60))
end

function overlap_ratio(conc, polygon)
    ratios = Float64[]
    for i in 1:length(dims(conc, Ti))
        horiz = conc[Ti=i]
        footprint_coords = nonmissingpoints(horiz)
        count_within = count(x -> AG.within(x, polygon), footprint_coords)
        ratio = count_within / length(footprint_coords)
        push!(ratios, ratio)
    end
    ratios
end

function nonmissingpoints(conc)
    points = AG.IGeometry[]
    lons = dims(conc, X)
    lats = dims(conc, Y)
    for I in DimIndices(conc)
        i, j = Tuple(I)
        if !ismissing(conc[I...]) && !(conc[I...] ≈ 0.)
            push!(points, AG.createpoint(lons[i.val], lats[j.val]))
        end
    end
    points
end

function feat2polygon(feat)
    coords = GeoJSON.coordinates(feat)[1]
    totuple = Tuple.([copy(coords)..., coords[1]])
    ArchGDAL.createpolygon(totuple)
end