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

# ╔═╡ 6c52137c-333a-11ed-02c3-9bec022e1391
begin
	using Pkg
	Pkg.activate("..")
	using ATP45
	using PlutoUI
	using Plots
	using GRIBDatasets
	using DimensionalData
	using Rasters
end

# ╔═╡ ab7c8e8e-7a47-4147-ae5b-c002d9d8731d
begin
	using Dates
	using GeoInterface
	using ATP45.GeoJSON
end

# ╔═╡ 169319aa-b256-4ab9-a9b8-ed551f8adfe4
begin
	GI = GeoInterface
	GJ = ATP45.GeoJSON
end

# ╔═╡ 7b3b0349-b902-4c45-a0f1-477ec7fd98e4
gr()

# ╔═╡ a04b2134-bcc3-419c-abcc-b14d6e4a2812
inputfile = "/home/tcarion/Documents/suffield/postprocess/inputs/ENH14081321"

# ╔═╡ e4d5cfac-4e4f-4ec7-83fb-e975a6a3925e
fpoutputfile = "/home/tcarion/Documents/suffield/postprocess/flexpart_outputs/NH3_132150_140000_ctl10_100m/output/grid_conc_20140813215400.nc"

# ╔═╡ 7004bd79-9961-4301-adec-1f1fa167e077
fpoutput = RasterStack(fpoutputfile)

# ╔═╡ 04f35ba8-6f53-47b4-bc25-a669b8d92efe
metadata(fpoutput) |> Dict

# ╔═╡ 63fcc28f-03ae-4fdc-983a-a9a2593f35cb
begin 
	released_mass = first(fpoutput[:RELXMASS]|>collect)
	sim_start = DateTime(fpoutput.metadata[:ibdate]*"T"*fpoutput.metadata[:ibtime], "yyyymmddTHHMMSS")
	release_start = first(Second.(fpoutput[:RELSTART]|>collect) .+ sim_start)
end

# ╔═╡ dc83fb7d-67b0-4a7c-ad5f-5f320aac3f24
fpoutput[:RELSTART].metadata

# ╔═╡ c11e40b6-83eb-40a8-b322-3e96d2d49d5b
spec001 = view(fpoutput[:spec001_mr], 
	pointspec = 1, nageclass = 1)

# ╔═╡ 7d817edb-e05d-498c-b37b-fc93c10ea313
begin
	getrelloc = x -> first(unique(x))
	relloc = (lon=fpoutput[:RELLNG1] |> getrelloc, lat=fpoutput[:RELLAT1] |> getrelloc)
end

# ╔═╡ 7cf1289d-8853-48f2-a1f5-128b664d6150
input_ds = GRIBDataset(inputfile)

# ╔═╡ 952bd7e2-8fbe-4e1a-8b0e-2ebca1c99bc9
begin 
	lons = input_ds["longitude"][:] .- 360
	lats = input_ds["latitude"][:]
	u10_raw = input_ds["u10"]
	v10_raw = input_ds["v10"]
	t2_raw = input_ds["t2m"]
end

# ╔═╡ ba2d3235-4096-4526-a350-95223b89c330
begin 
	u10 = DimArray(u10_raw[:,:,1,1], (X = lons, Y = lats))
	v10 = DimArray(v10_raw[:,:,1,1], (X = lons, Y = lats))
	t2 = DimArray(t2_raw[:,:,1,1], (X = lons, Y = lats))
end

# ╔═╡ e723db4d-fb01-4c3a-ad32-00c394d56416
begin
	near_u = u10[X(Near(relloc.lon)), Y(Near(relloc.lat))]
	near_v = v10[X(Near(relloc.lon)), Y(Near(relloc.lat))]
	(near_u, near_v)
end

# ╔═╡ 1db46d28-b8de-4c85-b9b8-a206cd628201
wind = WindCoords(near_u * 3.6, near_v * 3.6)

# ╔═╡ fa503a93-15fb-4e55-b985-26090bd3d72b
atpinput = Atp45Input(
	[convert(Array{Float64}, collect(relloc))],
	wind,
	:BOM,
	:simplified,
	ATP45.Stable
)

# ╔═╡ e94e827b-fd27-42f1-a9ce-dc1f0399be6f
atp_res = run_chem(atpinput)

# ╔═╡ 4a7a1b80-2d10-4511-b0c0-e6ed997c3bca
ATP45.resultplot(atp_res)

# ╔═╡ f80a1959-005b-4132-83ca-9bf6dc2de5ef
begin
	fp_lons = dims(spec001, :X) |> collect
	fp_lats = dims(spec001, :Y) |> collect
end

# ╔═╡ 54d4e109-b8a6-43c3-bdb6-506af629f407
@bind xzs RangeSlider(1:length(fp_lons))

# ╔═╡ 8612748d-2e58-41e1-9148-3e0b56371eca
@bind yzs RangeSlider(1:length(fp_lats))

# ╔═╡ 2cf9e229-e8b3-4eb2-b2d1-46ce2804b4c0
zoomed_x = (fp_lons[xzs[1]])..(fp_lons[xzs[end]])

# ╔═╡ e638da5c-c3b3-4e0e-bca5-668bd2f24c85
zoomed_y = (fp_lats[yzs[1]])..(fp_lats[yzs[end]])

# ╔═╡ 2de33e35-b292-4cc6-bc6c-5120fb797a47
function mask_thres(A, thres)
	replace(x -> !ismissing(x) && x < thres ? missing : x, A)
end

# ╔═╡ 88be09c2-f0be-445e-8067-64501ed34328
fp_lons[2] - fp_lons[1]

# ╔═╡ 207c0dd9-b748-4a3a-8b67-6d2ca8b71fa3
function make_range(r, s)
	e = extrema(r)
	e[1]:s:e[2]
end

# ╔═╡ bd539b7d-2ebc-448d-9775-f1c45b58a64b
function create_rast(lons, lats, res)
	nlons, nlats = length(lons), length(lats)
	xs = make_range(lons, res)
	ys = make_range(lats, res)
	Raster(DimArray(rand(length(xs), length(ys)), (X=xs, Y=ys)))
end

# ╔═╡ 95bd6435-bf2e-4d90-973a-50e60d0c373e
srast = create_rast(fp_lons, fp_lats, 0.001)

# ╔═╡ 0f840289-4aea-40e0-8754-41531de3177a
function plot_fp(conc)
	reftime = refdims(conc, Ti) |> collect |> first
	after_rel = canonicalize(reftime - release_start)
	# toplot = trim(replace(conc, 0. => missing) ./ released_mass ./ 1e3)
	toplot = trim(replace(conc, 0. => missing))
	heatmap(toplot, levels=3,
		clim = (0, maximum(skipmissing(toplot))),
		c = :thermal,
		title = "time after release = $after_rel",
		xlabel = "",
		ylabel = "",
	)
end

# ╔═╡ 887c90f4-cfa0-4053-bdf2-a95a25db69ed
_pair_ind(vec) = [i => vec[i] for i in eachindex(vec)]

# ╔═╡ e38f5f8a-900a-4ab7-a096-18a3605de953
@bind itime Select(_pair_ind(dims(spec001, Ti) |> collect))

# ╔═╡ e88e1cae-5349-427d-8c50-eb23c897a60f
@bind iheight Select(_pair_ind(dims(spec001, :height) |> collect))

# ╔═╡ 114910fd-28f5-4256-80e6-00058c0b3dba
# horiz_spec = spec001[Ti = itime, height = iheight]
horiz_spec = view(spec001, 
	Ti = itime, 
	height = iheight,
	X(zoomed_x),
	Y(zoomed_y),
)

# ╔═╡ 757eeb1b-13dc-4164-b2d4-c357763b25a4
dims(horiz_spec, Y)

# ╔═╡ d88ebe20-a945-49b4-a062-bdaca95739fc
horiz_spec_filtered = replace(horiz_spec, 0. => NaN);

# ╔═╡ 413a8a4b-7a7c-4f6e-b40f-775e8820aaea
begin
	# contourf(replace(log10.(horiz_spec), -Inf => 0.0))
	# contourf(replace(horiz_spec, -Inf => 0.0), levels=3)
	# heatmap(replace(horiz_spec, -Inf => 0.0) ./ released_mass ./ 1e3, levels=3, c = :bilbao)
	plot_fp(horiz_spec)
	ATP45.resultplot!(atp_res)
	plot!(aspect_ratio = 1., xlim=[-110.85, -110.55], ylim=[50.2, 50.4])
end

# ╔═╡ 758be6e3-e0b9-4808-be4f-77ad49d75e99
trimed_horiz = trim(replace(horiz_spec, 0. => missing))

# ╔═╡ 0da267bc-3fcc-442f-b0ff-d9c41798c769
max_masked = maximum(horiz_spec)

# ╔═╡ 2bca6b8c-da82-40e7-833e-960b2871b2dd
@bind thres Slider(0:2000:max_masked, show_value=true)

# ╔═╡ e2929645-e01a-4fc1-ac48-f9767b367a02
masked_trimed_horiz = mask_thres(trimed_horiz, thres)

# ╔═╡ 592c959d-b5ac-490a-80ce-77b1c6a01520
plot_fp(masked_trimed_horiz)

# ╔═╡ e6d1d241-5c0f-4ddb-a3c0-fe50ef2d2081
resampled = resample(horiz_spec, srast)

# ╔═╡ 28df4e20-d602-4369-ae80-507a78ea242c
resample(horiz_spec, 0.01)

# ╔═╡ 0a783146-2002-4a24-9944-d2e0188809f7
horiz_spec

# ╔═╡ bb07fc1a-921b-4c86-a6af-bca2df22b293
function flatwind(u, v, Xs, Ys)
    n = size(u, 1)
    m = size(u, 2)
    us = zeros(length(u))
    vs = zeros(length(u))
    xs = zeros(length(u))
    ys = zeros(length(u))
    for j in axes(u, 2)
            for i in axes(u, 1)
                    us[(i-1)*m+j] = u[i,j]
                    vs[(i-1)*m+j] = v[i,j]
                    xs[(i-1)*m+j] = Xs[i]
                    ys[(i-1)*m+j] = Ys[j]
            end
    end
    us, vs, xs, ys
end

# ╔═╡ 2f485bab-7e37-49fb-b4d1-5adb22674b01
begin
	@userplot WindPlot
	
	@recipe function f(h::WindPlot)
		u = h.args[1]
		v = h.args[2]
		lons = dims(u, :X) |> collect
		lats = dims(u, :Y) |> collect
		us, vs, xs, ys = flatwind(u, v, lons, lats)
		for I in eachindex(us)
			vnorm = sqrt(us[I].^2 + vs[I].^2)
			us[I] = us[I] ./ vnorm
			vs[I] = vs[I] ./ vnorm
		end
		quiver(xs, ys, quiver = (us, vs))
	end
end

# ╔═╡ e46d03c5-1bf1-45a4-97dc-978e3cece710
begin
	u = u10
	v = v10
end

# ╔═╡ 6dee0de6-e227-4a73-97cc-f4c300085445
function windplot_(u, v)
	lons = dims(u, :X) |> collect
	lats = dims(u, :Y) |> collect
	us, vs, xs, ys = flatwind(u, v, lons, lats)
	for I in eachindex(us)
		vnorm = sqrt(us[I].^2 + vs[I].^2)
		us[I] = us[I] ./ vnorm ./ 10
		vs[I] = vs[I] ./ vnorm ./ 10
	end
	quiver(xs, ys, quiver = (us, vs))
end

# ╔═╡ 48b1bea4-d148-466f-a6be-665038561558
windplot_(u10[1:25, 1:25], v10[1:25, 1:25])

# ╔═╡ a87fb303-115a-4da5-a5ba-424caeb2cf97
windplot(u10, v10)

# ╔═╡ 510b41b2-8fb2-48f7-9573-e782cc781c85
flatwind(u10, v10, lons, lats)

# ╔═╡ fa960a1c-f79f-449f-b119-06fec8d56212
axes(u10, 1)

# ╔═╡ b6392338-874b-41d2-a544-903db8c1bdae
length(u10)

# ╔═╡ b092686f-2680-4e2c-beda-70a489bfa124
quiver

# ╔═╡ Cell order:
# ╠═6c52137c-333a-11ed-02c3-9bec022e1391
# ╠═ab7c8e8e-7a47-4147-ae5b-c002d9d8731d
# ╠═169319aa-b256-4ab9-a9b8-ed551f8adfe4
# ╠═7b3b0349-b902-4c45-a0f1-477ec7fd98e4
# ╠═a04b2134-bcc3-419c-abcc-b14d6e4a2812
# ╠═e4d5cfac-4e4f-4ec7-83fb-e975a6a3925e
# ╠═7004bd79-9961-4301-adec-1f1fa167e077
# ╠═04f35ba8-6f53-47b4-bc25-a669b8d92efe
# ╠═63fcc28f-03ae-4fdc-983a-a9a2593f35cb
# ╠═dc83fb7d-67b0-4a7c-ad5f-5f320aac3f24
# ╠═c11e40b6-83eb-40a8-b322-3e96d2d49d5b
# ╠═7d817edb-e05d-498c-b37b-fc93c10ea313
# ╠═7cf1289d-8853-48f2-a1f5-128b664d6150
# ╠═952bd7e2-8fbe-4e1a-8b0e-2ebca1c99bc9
# ╠═ba2d3235-4096-4526-a350-95223b89c330
# ╠═e723db4d-fb01-4c3a-ad32-00c394d56416
# ╠═1db46d28-b8de-4c85-b9b8-a206cd628201
# ╠═fa503a93-15fb-4e55-b985-26090bd3d72b
# ╠═e94e827b-fd27-42f1-a9ce-dc1f0399be6f
# ╠═4a7a1b80-2d10-4511-b0c0-e6ed997c3bca
# ╠═f80a1959-005b-4132-83ca-9bf6dc2de5ef
# ╠═e38f5f8a-900a-4ab7-a096-18a3605de953
# ╠═e88e1cae-5349-427d-8c50-eb23c897a60f
# ╠═54d4e109-b8a6-43c3-bdb6-506af629f407
# ╠═8612748d-2e58-41e1-9148-3e0b56371eca
# ╠═2cf9e229-e8b3-4eb2-b2d1-46ce2804b4c0
# ╠═e638da5c-c3b3-4e0e-bca5-668bd2f24c85
# ╠═114910fd-28f5-4256-80e6-00058c0b3dba
# ╠═757eeb1b-13dc-4164-b2d4-c357763b25a4
# ╠═d88ebe20-a945-49b4-a062-bdaca95739fc
# ╠═413a8a4b-7a7c-4f6e-b40f-775e8820aaea
# ╠═758be6e3-e0b9-4808-be4f-77ad49d75e99
# ╠═2bca6b8c-da82-40e7-833e-960b2871b2dd
# ╠═e2929645-e01a-4fc1-ac48-f9767b367a02
# ╠═0da267bc-3fcc-442f-b0ff-d9c41798c769
# ╠═592c959d-b5ac-490a-80ce-77b1c6a01520
# ╠═2de33e35-b292-4cc6-bc6c-5120fb797a47
# ╠═e6d1d241-5c0f-4ddb-a3c0-fe50ef2d2081
# ╠═28df4e20-d602-4369-ae80-507a78ea242c
# ╠═88be09c2-f0be-445e-8067-64501ed34328
# ╠═0a783146-2002-4a24-9944-d2e0188809f7
# ╠═95bd6435-bf2e-4d90-973a-50e60d0c373e
# ╠═bd539b7d-2ebc-448d-9775-f1c45b58a64b
# ╠═207c0dd9-b748-4a3a-8b67-6d2ca8b71fa3
# ╠═0f840289-4aea-40e0-8754-41531de3177a
# ╠═887c90f4-cfa0-4053-bdf2-a95a25db69ed
# ╠═bb07fc1a-921b-4c86-a6af-bca2df22b293
# ╠═2f485bab-7e37-49fb-b4d1-5adb22674b01
# ╠═e46d03c5-1bf1-45a4-97dc-978e3cece710
# ╠═48b1bea4-d148-466f-a6be-665038561558
# ╠═6dee0de6-e227-4a73-97cc-f4c300085445
# ╠═a87fb303-115a-4da5-a5ba-424caeb2cf97
# ╠═510b41b2-8fb2-48f7-9573-e782cc781c85
# ╠═fa960a1c-f79f-449f-b119-06fec8d56212
# ╠═b6392338-874b-41d2-a544-903db8c1bdae
# ╠═b092686f-2680-4e2c-beda-70a489bfa124
