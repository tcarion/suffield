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

# ╔═╡ 5249839b-52a2-4564-adfa-87465ba907f4
begin
	using Pkg
	Pkg.activate("..")
	include("../scripts/read_sensor_pm.jl")
	include("../scripts/read_recept.jl")
	using Flexpart
	using Plots
	using PlutoUI
	using Rasters
end

# ╔═╡ 118e78f3-c042-489d-b2e4-de7a332ed941
using Unitful, Dates

# ╔═╡ 830fa648-13f4-4589-b621-75e7ba9eca79
@bind fppath Select(filter(isdir, readdir("../flexpart_outputs/aerosols", join = true)))

# ╔═╡ 1811e3f7-f49e-42c8-8241-8f9bd00cf8ce
fpdir = FlexpartDir(fppath)

# ╔═╡ cdc5d4f4-fd12-42d8-a96e-c7e47bee6cbd
stack = RasterStack(OutputFiles(fpdir)[1].path)

# ╔═╡ bccb352a-1d51-403c-8b0f-f36a7a4258f4
num_receptor = 2

# ╔═╡ 9250db05-a36c-46ea-9bd5-a263c95bd497
sensor = read_sensor_pm("../sensors_ds/Aerosol_SiteA_release.xlsx", "1808_J4230 MS"; rho = 1174)

# ╔═╡ c3d9f99a-a74c-4489-8e0e-d69880f20ff8
receptors = read_receptor(fpdir, num_receptor; rectype = "conc")

# ╔═╡ cb9bf59b-4026-41f9-822f-a9a288b5d9bc
begin
	rellon = stack[:RELLNG1][1]
	rellat = stack[:RELLAT1][1]
	(rellon, rellat)
end

# ╔═╡ c6941ed7-797a-450c-98d5-005f4206cb0b
@bind timerange RangeSlider(1:length(dims(stack, Ti)))

# ╔═╡ 56be09e7-0731-4f48-b618-61a4fa27c504
spec_conc = view(stack[:spec001_mr],
	Ti(timerange),
	Dim{:pointspec}(1),
	Dim{:nageclass}(1),
) |> read

# ╔═╡ 5bb59626-b916-4696-b5de-37a3ef5ef574
begin
	times = dims(spec_conc, Ti) |> collect
	lons = dims(spec_conc, X) |> collect
	lats = dims(spec_conc, Y) |> collect
	heights = dims(spec_conc, Dim{:height}) |> collect
end

# ╔═╡ 881ae380-f836-4c24-a89b-a2d55877562b
md"""
Time : $(@bind itime Slider(1:length(dims(spec_conc, Ti))))
"""

# ╔═╡ 5a22ca28-29f2-4fa0-9777-721c227a37d2
md""" Date: **$(times[itime])**"""

# ╔═╡ 7c099e55-f351-4d72-bff1-8aa104bcea0b
md"""
Height = $(@bind iheight Slider(1:length(heights)))
"""

# ╔═╡ 952a7de9-f031-4a72-92f0-78516eec59a9
md""" Height: **$(heights[iheight])**"""

# ╔═╡ 94620d27-f4f5-477f-be1e-ba9f8f59c7b6
md"""
Zoom = lons: $(@bind xrange RangeSlider(1:length(lons))) lats: $(@bind yrange RangeSlider(1:length(lats)))
"""

# ╔═╡ bdd048c6-ebe2-4737-b5db-b9d49aba755e
horizplot(horiz) = plot(horiz, xlabel = "", ylabel = "", title = refdims(horiz, Ti)[1], titlefontsize=7)

# ╔═╡ 4ebe75cd-7bc7-40a8-8ef6-5f50aad86b68
midpoint(a) = a[Int(floor(length(a)/2))]

# ╔═╡ 72c84abd-8578-48c9-a7c9-3b33dfac6d85
md"""
Receptor: $(@bind ireclon Scrubbable(xrange, default = midpoint(xrange))) - $(@bind ireclat Scrubbable(yrange, default = midpoint(yrange)))
"""

# ╔═╡ a3326d3a-beeb-4323-bda5-a725dd725075
begin
	reclon = lons[ireclon]
	reclat = lats[ireclat]
end;

# ╔═╡ c7cd7e03-9031-42d7-b8f1-cb6facf76607
(reclon, reclat)

# ╔═╡ 83c588f8-b636-4821-aa0f-db9499261cf6
begin
	gr()
	horiz = view(spec_conc, 
		X(xrange),
		Y(yrange),
		Ti(itime),
		Dim{:height}(iheight)
	)
	horizplot(horiz)
	plot!((rellon, rellat), marker = :star, markersize= :6, label= false)
	plot!((reclon, reclat), marker = :dot, markersize= :4, label= false)
end

# ╔═╡ 5c911f43-8e4e-4898-b2cd-9d5be66d9bad
begin
	plotly()
	tsloc = view(spec_conc, 
		X(ireclon),
		Y(ireclat),
		Dim{:height}(iheight)
	)
	plot(legend = :topleft,
		xrotation = 10,
		ylabel = "mg m-3"
	)
	plot!(times, collect(tsloc[Ti(:)]) * 1e-6,
		label = basename(fppath),
		marker = :square,
		markersize = 0.2,
	)
	plot!(sensor.time, ustrip.(sensor.concentration .|> u"mg/m^3"),
		label = "sensor data",
		marker = :square,
		markersize = 0.2,
	)

	for receptor in receptors
		plot!(receptor.time, receptor.concentration .* 1e-6, 
			label = receptor.name,
			marker=:dot,
			markersize=1,
		)
	end
	current()
end

# ╔═╡ 248f1713-8d7e-413c-8909-8445e0b6e6c5
begin
	vertical = view(spec_conc, 
		X(ireclon),
		Y(ireclat),
		Ti(itime)
	)
	plot(vertical * 1e-6, heights, title="vertical cut at $reclon, $reclat",
		marker=:dot
	)
end

# ╔═╡ Cell order:
# ╠═5249839b-52a2-4564-adfa-87465ba907f4
# ╠═118e78f3-c042-489d-b2e4-de7a332ed941
# ╠═830fa648-13f4-4589-b621-75e7ba9eca79
# ╠═1811e3f7-f49e-42c8-8241-8f9bd00cf8ce
# ╠═cdc5d4f4-fd12-42d8-a96e-c7e47bee6cbd
# ╠═bccb352a-1d51-403c-8b0f-f36a7a4258f4
# ╠═9250db05-a36c-46ea-9bd5-a263c95bd497
# ╠═c3d9f99a-a74c-4489-8e0e-d69880f20ff8
# ╟─cb9bf59b-4026-41f9-822f-a9a288b5d9bc
# ╠═c6941ed7-797a-450c-98d5-005f4206cb0b
# ╠═56be09e7-0731-4f48-b618-61a4fa27c504
# ╠═5bb59626-b916-4696-b5de-37a3ef5ef574
# ╟─881ae380-f836-4c24-a89b-a2d55877562b
# ╟─5a22ca28-29f2-4fa0-9777-721c227a37d2
# ╟─7c099e55-f351-4d72-bff1-8aa104bcea0b
# ╟─952a7de9-f031-4a72-92f0-78516eec59a9
# ╠═94620d27-f4f5-477f-be1e-ba9f8f59c7b6
# ╟─72c84abd-8578-48c9-a7c9-3b33dfac6d85
# ╟─a3326d3a-beeb-4323-bda5-a725dd725075
# ╠═c7cd7e03-9031-42d7-b8f1-cb6facf76607
# ╠═83c588f8-b636-4821-aa0f-db9499261cf6
# ╠═5c911f43-8e4e-4898-b2cd-9d5be66d9bad
# ╠═248f1713-8d7e-413c-8909-8445e0b6e6c5
# ╠═bdd048c6-ebe2-4737-b5db-b9d49aba755e
# ╠═4ebe75cd-7bc7-40a8-8ef6-5f50aad86b68
