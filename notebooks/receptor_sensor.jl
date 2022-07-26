### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 3d72aa34-f399-11ec-0c2d-73517f7f39b6
begin
	using Pkg
	Pkg.activate("..")
	using PlutoUI
	using Flexpart
	using Rasters
	using Plots
	using Dates
	using DataFrames
	plotly()
end

# ╔═╡ 8da0b694-6d98-4e5c-8745-bb4fc7c2726b
begin
	include("../scripts/read_sensors.jl")
	include("../scripts/read_recept.jl")
end

# ╔═╡ 1181dbd3-d759-4098-9cb6-066da2fd050d
cd("..")

# ╔═╡ 2b89e6d5-b01d-4a8c-bf6d-bd38ed19bc1a
@bind fppath Select(filter(isdir, readdir("../flexpart_outputs", join = true)))

# ╔═╡ 89bf5e33-7e0b-49bd-8fbc-2570598d97de
@bind rectype Select(["conc", "pptv"])

# ╔═╡ 14417a47-fc21-4a73-be64-931d0ecd4d31
@bind sensor_path Select(readdir("../sensors_ds/xams", join = true))

# ╔═╡ 4018097a-ddf1-45d5-945c-8dc2f6d2d995
# sensor = sensor_log(sensor_path, "nh3")

# ╔═╡ af0f59a5-5826-4297-a046-34c866647b1c
# plot(sensor.time, sensor.nh3, xrotation = 10, label =false, ylabel = "conc [ppm]");

# ╔═╡ f44fa436-b42e-4016-b12c-19f866cbecb7
molarmass = 17 # [g/mol]

# ╔═╡ 7b33bf6e-9292-4a15-a992-3438b44893e9
fpdir = FlexpartDir(fppath)

# ╔═╡ 528d805e-b581-4f3d-a7fe-30f763e2ff42
stack = RasterStack(OutputFiles(fpdir)[1].path)

# ╔═╡ 54bd0550-17e0-441f-9c78-19829b38536a
crs(stack)

# ╔═╡ e253f09a-4f19-431a-b11c-293c4665a5e4
num_receptor = 1

# ╔═╡ 8fe1f0b1-81bd-4fee-a16a-84dff9fca1c0
spec001_mr = stack[rectype == "conc" ? :spec001_mr : :spec001_pptv]

# ╔═╡ db5d1e62-4421-40e8-8245-6e9a82b8a131
spec001_mr.metadata[:units]

# ╔═╡ f152f0f9-76c7-4839-bf2f-c4f9847b55c0
# sensloc = (lon = -110.774254, lat = 50.2545776)
sensloc = (lon = -110.7728, lat = 50.255802)

# ╔═╡ 82f02d7f-0735-40c0-b82f-56a83834fffc
timeseries_all = view(spec001_mr,
	Dim{:nageclass}(1),
	X(Near(sensloc.lon)),
	Y(Near(sensloc.lat)),
)

# ╔═╡ 776bd46e-7545-47db-8eb4-e08d69d7a93d
timeseries = sum(timeseries_all; dims = Dim{:pointspec})[Dim{:pointspec}(1)]

# ╔═╡ 51d4f8ee-6b5f-4ab8-a97b-ba83c6051488
receptors = read_receptor(fpdir, num_receptor; rectype = rectype)

# ╔═╡ b174bf28-6f8c-4b4c-ba18-fbef38c6be70
# begin
# 	newreceptor = copy(receptor)
# 	if rectype == "conc"
# 		newreceptor.ppm = conctoppm.(receptor.conc .* 1e-9)
# 	elseif rectype == "pptv"
# 		newreceptor.ppm = receptor.pptv * 1e-6
# 	end
# end;

# ╔═╡ 47812ed5-e68b-4568-98d5-2c5ed23f91e9
xam1766 = read_sensors(sheetname = "1308_J4225", cols = ["D", "F"]);

# ╔═╡ 5382297f-a05e-449f-9ed3-2b17f9dddd6b
xam2083 = read_sensors(sheetname = "1308_J4225", cols = ["L", "N"]);

# ╔═╡ 2a779a19-0802-4a23-8506-a11dc306962c
xam2082 = read_sensors(sheetname = "1308_J4225", cols = ["T", "V"]);

# ╔═╡ 0f48bd0e-f0b4-4c69-ad72-f2b88be33dc5
@bind timerange RangeSlider(1: length(receptors[1].time))

# ╔═╡ 1919828f-2579-42cb-a13d-a12296a90bbf
@bind iheight Slider(dims(spec001_mr, Dim{:height}) |> collect, show_value=true)

# ╔═╡ e8e88dd0-f264-413c-bcb4-b3aac83b1ee0
rectype

# ╔═╡ e60641d7-f074-4d06-942d-da583a91b1a6
simstart = DateTime(stack.metadata[:ibdate]*"T"*stack.metadata[:ibtime], "yyyymmddTHHMMSS")

# ╔═╡ faa8746c-2310-463d-b70a-baf3e8d294cb
relstarts = simstart .+ Second.(stack[:RELSTART]) |> collect

# ╔═╡ 8de52db8-50a9-4e0e-8b25-7d5dbc4f92c4
relstops = simstart .+ Second.(stack[:RELEND]) |> collect

# ╔═╡ 3a554eb8-9a0d-4185-9e22-6121ebab7fe6
relcoms = join.([stack[:RELCOM][:, i] for i in 1:length(dims(stack, Dim{:pointspec}))])

# ╔═╡ 5b54ef9b-e5e2-4dab-8ff4-f99533b7321e
conctoppm(c) = c * 8.314472 * (288) / (molarmass * 1e5) * 1e6

# ╔═╡ 203efa0a-75a9-4a6f-bc7d-35b52ee17b70
"""
output units: g m-3
"""
ppmtoconc(c) = c * molarmass * 1e5 / (1e6 * 8.314472 * 288)

# ╔═╡ 5f21fca5-b0cd-4dd8-9914-4437691722d5
molarmass * 1e5 / (1e6 * 8.314472 * 288)

# ╔═╡ bdaa69d4-c864-4bbd-87eb-e042cbd32985
macro NT(ex)
	Expr(:tuple, [Expr(:(=), esc(arg), arg) for arg in ex.args]...)
end

# ╔═╡ aba5e716-3a5b-42e6-85f8-98e4da4d1521
# sensors = (xam1766=xam1766, xam2082=xam2082, xam2083=xam2083)
# sensors = @NT xam1766, xam2082, xam2083
sensors = @NT xam1766, xam2082, xam2083

# ╔═╡ 06381ed1-1c64-4f6f-ab27-f038cb83b474
begin
	p = plot(
		title="NH3 concentration",
		ylabel = "concentration [mg/m3]",
		xrotation = 8,
		marker=:dot,
		markersize=1,
		# xticks = extrema(newreceptor.time[timerange]) |> collect
	)
	# plot!(p, receptor.time[timerange], receptor.conc .* 1e-6, 
	# 	label = "receptor",
	# 	marker=:dot,
	# 	markersize=1,
	# )
	for receptor in receptors
		plot!(p, receptor.time, receptor.concentration .* 1e-6, 
			label = receptor.name,
			marker=:dot,
			markersize=1,
		)
	end
	# plot!(dims(timeseries, Ti)[timerange] |> collect, conctoppm.(collect(timeseries[Dim{:height}(At(iheight))]) .* 1e-9)[timerange],
	# 	marker=:dot,
	# 	markersize=1,
	# )
	plot!(dims(timeseries, Ti)[timerange] |> collect, collect(timeseries[Dim{:height}(At(iheight))][timerange]) * 1e-6,
		marker=:dot,
		markersize=1,
		label="nearest"
	)
	# p = plot()
	for (name, sensor) in pairs(sensors)
		# plot!(p, sensor.time, ppmtoconc.(sensor.ppm) * 1e3, label = string(name),
		# 	marker = :square,
		# 	markersize = 0.2,
		# )
		if rectype == "conc"
			plot!(p, sensor.time, ppmtoconc.(sensor.ppm) * 1e3, label = string(name),
				marker = :square,
				markersize = 0.2,
			)
		else
			plot!(p, sensor.time, sensor.ppm, label = string(name),
				marker = :square,
				markersize = 0.2,
			)
		end
	end
	for (s, e) in zip(relstarts, relstops)
		plot!([(s, 0), (e, 0)],
			lw = 5,
			label=false
		)
	end
	p
end

# ╔═╡ 1d7562ab-455e-444a-86b5-a86a0bf11231
begin
	plot(
		xticks = DateTime(2014, 8, 13, 21, 40):Second(15):DateTime(2014, 8, 13, 22),
		xrotation = 45, 
	)
	for (name, sensor) in pairs(sensors)
		plot!(sensor.time, sensor.ppm, label = string(name),
			marker = :square,
			markersize = 0.2,
		)
	end
	for (s, e, relcom) in zip(relstarts, relstops, relcoms)
		plot!([(s, 0), (e, 0)],
			lw = 5,
			label=relcom
		)
	end
	current()
end

# ╔═╡ dee1c677-f596-44a3-a998-bf19614bb009
function sensor_log(filepath, specie)
    function isnum(a)
        try 
            parse(Float64, a)
        catch
            return false
        end
        true
    end

    dformat = "m/d/yyyy HH:MM:SS p"

    lines = readlines(filepath)

    specie = specie

    gastypes = lines[findfirst(x -> occursin("GASTYPE", x), lines)]
    gastypes_v = split(split(gastypes, ";;")[2], ";")
    igas = findfirst(x -> occursin(specie, lowercase(x)), gastypes_v)

    vals = filter(x -> occursin("VAL",x), lines)

    svals = split.(vals, ";")

    sval = first(svals)
    datestring = [sval[2] for sval in svals]
    dates = DateTime.(datestring, dformat)

    nh3 = [sval[igas] for sval in svals]

    nh3df = DataFrame(time = dates, nh3 = nh3)

    filter_nh3df = filter(:nh3 => isnum, nh3df)

    filter_nh3df.nh3 = parse.(Float64, filter_nh3df.nh3)
    filter_nh3df
end

# ╔═╡ Cell order:
# ╠═3d72aa34-f399-11ec-0c2d-73517f7f39b6
# ╠═8da0b694-6d98-4e5c-8745-bb4fc7c2726b
# ╠═1181dbd3-d759-4098-9cb6-066da2fd050d
# ╠═2b89e6d5-b01d-4a8c-bf6d-bd38ed19bc1a
# ╠═89bf5e33-7e0b-49bd-8fbc-2570598d97de
# ╠═14417a47-fc21-4a73-be64-931d0ecd4d31
# ╠═4018097a-ddf1-45d5-945c-8dc2f6d2d995
# ╠═af0f59a5-5826-4297-a046-34c866647b1c
# ╠═f44fa436-b42e-4016-b12c-19f866cbecb7
# ╠═7b33bf6e-9292-4a15-a992-3438b44893e9
# ╠═528d805e-b581-4f3d-a7fe-30f763e2ff42
# ╠═54bd0550-17e0-441f-9c78-19829b38536a
# ╠═e253f09a-4f19-431a-b11c-293c4665a5e4
# ╠═8fe1f0b1-81bd-4fee-a16a-84dff9fca1c0
# ╠═db5d1e62-4421-40e8-8245-6e9a82b8a131
# ╠═f152f0f9-76c7-4839-bf2f-c4f9847b55c0
# ╠═82f02d7f-0735-40c0-b82f-56a83834fffc
# ╠═776bd46e-7545-47db-8eb4-e08d69d7a93d
# ╠═51d4f8ee-6b5f-4ab8-a97b-ba83c6051488
# ╠═b174bf28-6f8c-4b4c-ba18-fbef38c6be70
# ╠═47812ed5-e68b-4568-98d5-2c5ed23f91e9
# ╠═5382297f-a05e-449f-9ed3-2b17f9dddd6b
# ╠═2a779a19-0802-4a23-8506-a11dc306962c
# ╠═aba5e716-3a5b-42e6-85f8-98e4da4d1521
# ╠═0f48bd0e-f0b4-4c69-ad72-f2b88be33dc5
# ╠═1919828f-2579-42cb-a13d-a12296a90bbf
# ╠═06381ed1-1c64-4f6f-ab27-f038cb83b474
# ╠═e8e88dd0-f264-413c-bcb4-b3aac83b1ee0
# ╠═1d7562ab-455e-444a-86b5-a86a0bf11231
# ╠═e60641d7-f074-4d06-942d-da583a91b1a6
# ╠═faa8746c-2310-463d-b70a-baf3e8d294cb
# ╠═8de52db8-50a9-4e0e-8b25-7d5dbc4f92c4
# ╠═3a554eb8-9a0d-4185-9e22-6121ebab7fe6
# ╠═5b54ef9b-e5e2-4dab-8ff4-f99533b7321e
# ╠═203efa0a-75a9-4a6f-bc7d-35b52ee17b70
# ╠═5f21fca5-b0cd-4dd8-9914-4437691722d5
# ╠═bdaa69d4-c864-4bbd-87eb-e042cbd32985
# ╠═dee1c677-f596-44a3-a998-bf19614bb009
