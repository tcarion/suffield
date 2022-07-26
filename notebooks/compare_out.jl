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

# ╔═╡ a871df8e-0277-11ed-1ac3-0106a023df4c
begin
	using Pkg
	Pkg.activate("..")
	using Flexpart
	using Rasters
	using Plots
	using PlutoUI
end

# ╔═╡ 205a6260-2a3f-4c5d-9ce8-4df1e4070a53
cd("..")

# ╔═╡ c274755b-cd66-49bd-a7be-acdc1603f56b
@bind fppath1 Select(filter(isdir, readdir("flexpart_outputs", join = true)))

# ╔═╡ 1a230376-cb8d-4479-bbb8-9ac5141043a0
@bind fppath2 Select(filter(isdir, readdir("flexpart_outputs", join = true)))

# ╔═╡ 7c27ff80-e05d-4177-b645-aa672514bec3
begin
	outputs1 = OutputFiles(FlexpartDir(fppath1))
	outputs2 = OutputFiles(FlexpartDir(fppath2))
end

# ╔═╡ e1661096-2527-4566-bbc1-03ec66cf15f2
md"""
Output 1: $(@bind output1 Select(OutputFiles(FlexpartDir(fppath1))))

Output 2: $(@bind output2 Select(OutputFiles(FlexpartDir(fppath2))))
"""

# ╔═╡ c01f68cd-e268-459d-9ed1-5517594fcecc
@bind outtype Select([1 => "mixing", 2 => "pptv"])

# ╔═╡ 5980612c-0a5d-4d78-bdca-56a32957d038
layername = outtype == 1 ? :spec001_mr : :spec001_pptv

# ╔═╡ 77589840-0d2c-42aa-964d-59cb94f7f6a1
begin
	stack1 = RasterStack(output1.path)
	stack2 = RasterStack(output2.path)
end

# ╔═╡ 555b5a1c-acce-4de4-96c8-c0cdb61b2381
spec001_mr1 = stack1[layername];

# ╔═╡ 13f3b47b-122e-42f1-9016-53408662c733
begin
	Xs1 = dims(spec001_mr1, X) |> collect
	Ys1 = dims(spec001_mr1, Y) |> collect
	Ti1 = dims(spec001_mr1, Ti) |> collect
end

# ╔═╡ 4d30170c-389a-4629-9008-1180eaa05f96
spec001_mr2 = stack2[layername];

# ╔═╡ 0affb351-4d6b-4ea3-85c6-da9d16129601
begin
	Xs2 = dims(spec001_mr2, X) |> collect
	Ys2 = dims(spec001_mr2, Y) |> collect
	Ti2 = dims(spec001_mr2, Ti) |> collect
end

# ╔═╡ 6ed116d2-beac-47cf-a1dd-affc3289d014
Xs2 |>length

# ╔═╡ 471c40e4-811b-42e8-bb93-2d99bd45c9b4
begin
	rellon = stack1[:RELLNG1][1]
	rellat = stack1[:RELLAT1][1]
	(rellon, rellat)
end

# ╔═╡ e23d57bd-b41d-441c-954f-4c1f5c6a0283
begin
	ds1 = spec001_mr1
	ds2 = spec001_mr2
end

# ╔═╡ c66e6003-18a5-4a34-b4e2-5983f4ac6c8e
md"""
Time zoom 1 = $(@bind timerange1 RangeSlider(1:length(dims(ds1, Ti))))

Time zoom 2 = $(@bind timerange2 RangeSlider(1:length(dims(ds2, Ti))))
"""

# ╔═╡ e8c66dbc-902b-4597-a1f5-ed7873e0bb2f
begin 
	zoomds1 = view(ds1,
		Ti(timerange1)
	)
	zoomds2 = view(ds2,
		Ti(timerange2)
	)
end

# ╔═╡ 0f7693d6-3900-46ac-95f8-8534aaa5a1d5
md"""
Height 1 = $(@bind height1 Slider(dims(spec001_mr1, Dim{:height}) |> collect, show_value = true))

Height 2 = $(@bind height2 Slider(dims(spec001_mr2, Dim{:height}) |> collect, show_value = true))
"""

# ╔═╡ d4a88990-ce3c-4578-b80a-935109f3bfeb
md"""
Time1 = $(@bind itime1 Slider(1:length(dims(zoomds1, Ti))))

Time2 = $(@bind itime2 Slider(1:length(dims(zoomds2, Ti))))
"""

# ╔═╡ 5ef073e1-a148-4214-8e0e-44a92f334ac5
begin
	time1 = collect(dims(zoomds1, Ti))[itime1]
	time2 = collect(dims(zoomds2, Ti))[itime2]
	(time1, time2)
end

# ╔═╡ b2d45593-d131-41f8-b975-88f4bf334a09
md"""
specs 1 = $(@bind rels1 RangeSlider(1:length(dims(spec001_mr1, Dim{:pointspec}))))
specs 2 = $(@bind rels2 RangeSlider(1:length(dims(spec001_mr2, Dim{:pointspec}))))
"""

# ╔═╡ 7a3352ac-b629-49dc-a520-9ce8be64c50f
md"""
Zoom1 = lons: $(@bind xrange1 RangeSlider(1:length(dims(spec001_mr1, :X)))) lats: $(@bind yrange1 RangeSlider(1:length(dims(spec001_mr1, :Y))))

Zoom2 = lons: $(@bind xxrange2 RangeSlider(1:length(dims(spec001_mr2, :X)))) lats: $(@bind yyrange2 RangeSlider(1:length(dims(spec001_mr2, :Y))))
"""

# ╔═╡ 179b19bd-340a-4f82-8a4a-29c9237387ba
md"""
Link zoom : $(@bind linkzoom CheckBox())
"""

# ╔═╡ 9735b0fe-8c08-4afd-9a01-4d98b831d747
if linkzoom
	xrange2 = xrange1
	yrange2 = yrange1
else
	xrange2 = xxrange2
	yrange2 = yyrange2
end

# ╔═╡ 4e79aebd-c4d2-4f07-8a18-660151f0827d
md"""
Link receptor: $(@bind linkrec CheckBox())
"""

# ╔═╡ 608b68b3-5413-4d1c-8832-5c757bd34f32
sensloc = (lon = -110.774254, lat = 50.2545776)

# ╔═╡ 4366cbb7-29c3-49ac-9bf1-844c24d20fa0
horizplot(horiz) = plot(horiz, xlabel = "", ylabel = "", title = refdims(horiz, Ti)[1], titlefontsize=7)

# ╔═╡ 4caab323-6e33-4745-bb77-e56be6e62bb7
selection(raster, height, itime, rels, xrange, yrange) = sum(view(raster,
		Ti(itime),
		Dim{:height}(At(height)),
		Dim{:nageclass}(1),
		Dim{:pointspec}(rels),
		X(xrange),
		Y(yrange),
), dims = Dim{:pointspec})

# ╔═╡ 89982c51-0aa3-48a0-adc7-cc92323ab211
selection(raster, height, rels, xrange, yrange) = sum(view(raster,
		Dim{:height}(At(height)),
		Dim{:nageclass}(1),
		Dim{:pointspec}(rels),
		X(xrange),
		Y(yrange),
), dims = Dim{:pointspec})

# ╔═╡ 87560abe-da83-4f21-aace-8bb6f1561124
begin
	ts1 = selection(zoomds1, height1, rels1, xrange1, yrange1)
	ts2 = selection(zoomds2, height2, rels2, xrange2, yrange2)
end;

# ╔═╡ e8e43b43-5e3d-4d9e-b5d2-3718be9ddbf6
vertical(raster, itime, rels, xloc, yloc) = sum(view(raster,
		Ti(itime),
		Dim{:nageclass}(1),
		Dim{:pointspec}(rels),
		X(At(xloc)),
		Y(At(yloc)),
	), dims = Dim{:pointspec})

# ╔═╡ 7d6bdded-576d-4403-85e9-7b9de962bebd
timeseries(raster, height, rels, ilon, ilat) = view(raster,
		Dim{:height}(At(height)),
		Dim{:nageclass}(1),
		Dim{:pointspec}(rels),
		X(ilon),
		Y(ilat),
)
# , dims = Dim{:pointspec})

# ╔═╡ 3a4abd5d-6acb-4a1f-b4aa-b9acfe854567
plotpoint!(p, raster, lon, lat) = plot!(p,
	(dims(raster, :X)[lon], dims(raster, :Y)[lat]),
	label = false,
	marker = :dot,
	# markersize = 2,
)

# ╔═╡ ab4a7e1b-604b-464e-9f24-2ffad6ad9b12
extr(dim, range) = extrema(collect(dim)[range])

# ╔═╡ 9f5b4fc1-400e-4d14-b078-c529dcb9f75f
md"""
lons, lats: $(extr(dims(spec001_mr1, :X), xrange1)), $(extr(dims(spec001_mr1, :Y), yrange1))
"""

# ╔═╡ 02757750-9c99-4a5b-86af-fab8cf8856ca
midpoint(a) = a[Int(floor(length(a)/2))]

# ╔═╡ 905354bd-9576-4875-a6a7-a60ea94e6584
md"""
Receptor1: $(@bind ireclon1 Scrubbable(xrange1, default = midpoint(xrange1))) - $(@bind ireclat1 Scrubbable(yrange1, default = midpoint(yrange1)))

Receptor2: $(@bind ireclon2 Scrubbable(xrange2, default = midpoint(xrange2))) - $(@bind ireclat2 Scrubbable(yrange2, default = midpoint(yrange2)))
"""

# ╔═╡ 4c4e871e-e2c8-4fbe-afd8-96924bbdc27d
begin
	reclon1 = collect(dims(zoomds1, :X))[ireclon1]
	reclat1 = collect(dims(zoomds1, :Y))[ireclat1]
	if linkrec
		reclon2 = reclon1
		reclat2 = reclat1
	else
		reclon2 = collect(dims(zoomds2, :X))[ireclon2]
		reclat2 = collect(dims(zoomds2, :Y))[ireclat2]
	end
end;

# ╔═╡ b17a3c04-968b-407a-9274-e6cf664a0679
(reclon1, reclat1)

# ╔═╡ 23edf9bd-e238-4925-a515-864091ecf20d
reclat1

# ╔═╡ 9057c7eb-9576-4ee7-82f5-8a54e29501d1
begin
	gr()
	horiz1 = selection(zoomds1, height1, itime1, rels1, xrange1, yrange1)
	horiz2 = selection(zoomds2, height2, itime2, rels2, xrange2, yrange2)
	l = @layout [a ; b]
	p1 = horizplot(horiz1 * 1e-6)
	p2 = horizplot(horiz2 * 1e-6)
	# plotpoint!(p1, zoomds1, ireclon, ireclat)
	# plotpoint!(p2, zoomds2, ireclon, ireclat)
	plot!(p1, (reclon1, reclat1), marker = :dot, markersize= :4, label= false)
	plot!(p2, (reclon2, reclat2), marker = :dot, markersize= :4, label= false)
	plot!(p1, (rellon, rellat), marker = :star, markersize= :6, label= false)
	plot!(p2, (rellon, rellat), marker = :star, markersize= :6, label= false)
	plot!(p1, (sensloc.lon, sensloc.lat), marker = :star, markersize= :6, label= false)
	plot!(p2, (sensloc.lon, sensloc.lat), marker = :star, markersize= :6, label= false)
	plot(p1, p2, layout = l)
end

# ╔═╡ 5d1dd1de-1e19-4bd3-8283-947b81e42098
begin
	deltalon = rellon - reclon1
	deltalat = rellat - reclat1
	sqrt(deltalon.^2 + deltalat.^2) * 111e3
end

# ╔═╡ d1f99547-c214-48b8-8ed6-6559c23d6c2d
begin
	plotly()
	tsloc1 = view(ts1, 
		X(At(reclon1)),
		Y(At(reclat1)),
	)
	tsloc2 = view(ts2, 
		X(Near(reclon2)),
		Y(Near(reclat2)),
	)
	plot(legend = :topleft,
		xrotation = 10,
		ylabel = "mg m-3"
	)
	plot!(dims(tsloc1, Ti) |> collect, collect(tsloc1[Ti(:)]) * 1e-6,
		label = basename(fppath1),
		marker = :square,
		markersize = 0.2,
	)
	plot!(dims(tsloc2, Ti) |> collect, collect(tsloc2[Ti(:)]) * 1e-6,
		label = basename(fppath2),
		marker = :square,
		markersize = 0.2,
	)
end

# ╔═╡ 267f3a56-f967-4725-8100-a7d4ad9d54fb
begin
	vertcut1 = vertical(zoomds1, itime1, rels1, reclon1, reclat1)
	vertcut2 = vertical(zoomds2, itime2, rels2, reclon2, reclat2)
	pvcut = plot(title = "vertical concentration"
		, xlabel = "mg / m³"
		, ylabel = "height [m]"
	)
	plot!(pvcut, vertcut1[Dim{:height}()] * 1e-6, dims(vertcut1, Dim{:height}) |> collect,
		marker = :dot
	)
	plot!(vertcut2[Dim{:height}()] * 1e-6, dims(vertcut2, Dim{:height}) |> collect,
		marker = :dot
	)
end

# ╔═╡ Cell order:
# ╠═a871df8e-0277-11ed-1ac3-0106a023df4c
# ╠═205a6260-2a3f-4c5d-9ce8-4df1e4070a53
# ╠═c274755b-cd66-49bd-a7be-acdc1603f56b
# ╠═1a230376-cb8d-4479-bbb8-9ac5141043a0
# ╠═7c27ff80-e05d-4177-b645-aa672514bec3
# ╟─e1661096-2527-4566-bbc1-03ec66cf15f2
# ╠═c01f68cd-e268-459d-9ed1-5517594fcecc
# ╠═5980612c-0a5d-4d78-bdca-56a32957d038
# ╠═77589840-0d2c-42aa-964d-59cb94f7f6a1
# ╠═555b5a1c-acce-4de4-96c8-c0cdb61b2381
# ╟─13f3b47b-122e-42f1-9016-53408662c733
# ╠═4d30170c-389a-4629-9008-1180eaa05f96
# ╠═0affb351-4d6b-4ea3-85c6-da9d16129601
# ╠═6ed116d2-beac-47cf-a1dd-affc3289d014
# ╠═471c40e4-811b-42e8-bb93-2d99bd45c9b4
# ╠═e23d57bd-b41d-441c-954f-4c1f5c6a0283
# ╟─c66e6003-18a5-4a34-b4e2-5983f4ac6c8e
# ╠═e8c66dbc-902b-4597-a1f5-ed7873e0bb2f
# ╟─0f7693d6-3900-46ac-95f8-8534aaa5a1d5
# ╟─d4a88990-ce3c-4578-b80a-935109f3bfeb
# ╟─5ef073e1-a148-4214-8e0e-44a92f334ac5
# ╟─b2d45593-d131-41f8-b975-88f4bf334a09
# ╟─7a3352ac-b629-49dc-a520-9ce8be64c50f
# ╟─9f5b4fc1-400e-4d14-b078-c529dcb9f75f
# ╟─179b19bd-340a-4f82-8a4a-29c9237387ba
# ╟─9735b0fe-8c08-4afd-9a01-4d98b831d747
# ╟─905354bd-9576-4875-a6a7-a60ea94e6584
# ╠═b17a3c04-968b-407a-9274-e6cf664a0679
# ╠═23edf9bd-e238-4925-a515-864091ecf20d
# ╟─4e79aebd-c4d2-4f07-8a18-660151f0827d
# ╟─4c4e871e-e2c8-4fbe-afd8-96924bbdc27d
# ╟─608b68b3-5413-4d1c-8832-5c757bd34f32
# ╠═9057c7eb-9576-4ee7-82f5-8a54e29501d1
# ╠═5d1dd1de-1e19-4bd3-8283-947b81e42098
# ╠═87560abe-da83-4f21-aace-8bb6f1561124
# ╠═d1f99547-c214-48b8-8ed6-6559c23d6c2d
# ╠═267f3a56-f967-4725-8100-a7d4ad9d54fb
# ╠═4366cbb7-29c3-49ac-9bf1-844c24d20fa0
# ╠═4caab323-6e33-4745-bb77-e56be6e62bb7
# ╠═89982c51-0aa3-48a0-adc7-cc92323ab211
# ╠═e8e43b43-5e3d-4d9e-b5d2-3718be9ddbf6
# ╠═7d6bdded-576d-4403-85e9-7b9de962bebd
# ╠═3a4abd5d-6acb-4a1f-b4aa-b9acfe854567
# ╟─ab4a7e1b-604b-464e-9f24-2ffad6ad9b12
# ╠═02757750-9c99-4a5b-86af-fab8cf8856ca
