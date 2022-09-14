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

# ╔═╡ 94e32f70-0409-11ed-0c62-93bd2ed23345
begin
	using Pkg
	Pkg.activate(".")
	using GaussianDispersion
	using XLSX
	using DataFrames
	using PlutoUI
	using Plots
	using DimensionalData
end

# ╔═╡ 8e436e9d-062c-4290-87b3-f6451b811739
cd("..")

# ╔═╡ a3332223-37cd-43fb-a6d9-b4159c70d949
datafile = "releases_ds/Input_parameters_chemicals_V6.xlsx"

# ╔═╡ 59e573f6-cb33-45bd-b54c-6f750833dddb
releases = DataFrame(XLSX.readtable(datafile, "Model_input_mod2"; first_row = 2)...)

# ╔═╡ 12ab9845-c490-4b7e-845b-f58ee29786e1
names(releases)

# ╔═╡ 97c3ca0a-b254-4ee5-8ea0-c1295ac28183
nrel = 22

# ╔═╡ f5f5d6ed-5982-4ee9-b757-c3d36a8c9ddf
releasedf = releases[nrel, :]

# ╔═╡ 5eb03efe-d38d-4098-9d8d-60d4e9fcf6c7
release = releasedf |> collect;

# ╔═╡ 7752ad2d-464e-4a6a-bf29-8cda5ce05d41
md"""
From experiment : $(@bind fromexp CheckBox())
"""

# ╔═╡ e7d55336-155c-49c7-af5a-428175aea98d
begin
	if fromexp
		# href = release[7]
		# Q = release[5]
		# u = release[6]
		# stab = Stabilities(release[8])
		# wind_dir = release[26]
	end
end

# ╔═╡ 334d4c78-07e6-489c-9558-1fd429c0cce9
md"""
wind: $(@bind u Slider(range(0.1, 15, 50), show_value = true))

Q: $(@bind Q Slider(range(0.1, 100, 50), show_value = true))

href: $(@bind href Slider(range(0.1, 100, 100), show_value = true))

stability: $(@bind stab Select([:A, :B, :C, :D, :E, :F]))

terrain: $(@bind terrain Select([Rural(), Urban()]))
"""

# ╔═╡ 8129e797-c070-49d1-8fdb-d8eeb0a7eff8
begin
	stability = Stabilities(stab)
	plume = GaussianDispersionParams()
	plume.release = ReleaseParams(h = href, Q = Q, u = u)
	plume.stabilities = stability
	plume.terrain = terrain
end;

# ╔═╡ 9cf8c8ba-047c-47e4-9ca5-5c27c2472223
N = 100;

# ╔═╡ b34cf39b-b300-440f-b76e-08035cec682c
md"""
x range : $(@bind xrange RangeSlider(range(0.01, 500, N)))

y range : $(@bind yrange RangeSlider(range(-100, 100, N)))

z range : $(@bind zrange RangeSlider(range(0, 100, 101)))
"""

# ╔═╡ a5b6052f-a90c-45da-ad7d-8e516a962e1d
md"""
x = $(@bind x Slider(range(extrema(xrange)..., 201), show_value = true, default = 0))

y = $(@bind y Slider(range(extrema(yrange)..., 201), show_value = true, default = 0))

z = $(@bind z Slider(range(0, 100, 101), show_value = true))
"""

# ╔═╡ b651d847-36f9-40d5-ad5d-f19762d67b9a
begin
	xs = range(extrema(xrange)..., N)
	ys = range(extrema(yrange)..., N)
	zs = range(extrema(zrange)..., N)
	# conc2d = reshape([plume(x, y, z) for x in xs, y in ys], (length(xs), length(ys)));
end;

# ╔═╡ 6e2fc6eb-1e48-4141-8bc6-56257fa30a19
array3d = DimArray([plume(xi, yi, zi) for xi in xs, yi in ys, zi in zs], (X(xs), Y(ys), Z(zs))) .* 1e3

# ╔═╡ 90913574-f83e-4d66-bef8-cbdaafe78ebe
# array2d = DimArray(conc2d, (X(xs), Y(ys))) .* 1e3;
array2d = array3d[Z(Near(z))]

# ╔═╡ bb68646c-7f13-4e80-a57f-aeef567188b5
# vertical = DimArray(plume.(x, y, zs) .* 1e3, Z(zs))
vertical = array3d[X(Near(x)), Y(Near(y))]

# ╔═╡ d909d3d1-947c-47a1-82cc-5317d9c75929
begin
	plotly()
	l = @layout [a b]
	ycut = array2d[Y(Near(y))]
	pdw = plot(xs,  ycut, title = "downwind conc at z = $z", ylabel = "mg/m³", xlabel="downwind distance [m]", 
		# ylim = [0, 1], 
		label = false,
		titlefontsize = 8
	)
	pver = plot(vertical, zs, title = "vertical conc at x = $(round(x, digits=2))", xlabel = "mg/m³", ylabel="vertical distance [m]", 
		titlefontsize = 8,
		# ylim = [0, 1], 
		label = false)
	plot!(pdw,(x, ycut[X(Near(x))]), marker = :dot, label = false)
	plot!(pver,(vertical[Z(Near(z))], z), marker = :dot, label = false)
	plot(pdw, pver)
end

# ╔═╡ 0f38e6cc-27ce-4b69-bb89-e334d0386694
begin
	gr()
	contour(array2d, fill=true, title = "horizontal conc [mg m-3]")
end

# ╔═╡ 6c89c478-a0a0-4d40-8af8-7e0777edc0d4
# maximum(replace(x -> isnan(x) ? 0. : x, array2d))
maximum(array3d)

# ╔═╡ bac9696b-b152-43fc-8db3-49e368471849
begin
	u_grib, v_grib = (3.0898361206054688, 2.01654052734375)
	wind_speed = release[6]
	wind_dir = release[26]
	θ = 270. - wind_dir
	u_obs = wind_speed * cosd(θ)
	v_obs = wind_speed * sind(θ)
	ec_speed = sqrt(u_grib^2 + v_grib^2)
end

# ╔═╡ aa285156-ca15-42b2-95c1-1b74f78ee9e9
quiver([0, 0],[0, 0],quiver=([u_grib, u_obs],[v_grib, v_obs]), xlims=[-5, 5], ylims=[-5, 5])

# ╔═╡ 326c8685-e9b5-44b2-843a-a8dc010aa682


# ╔═╡ Cell order:
# ╠═94e32f70-0409-11ed-0c62-93bd2ed23345
# ╠═8e436e9d-062c-4290-87b3-f6451b811739
# ╠═a3332223-37cd-43fb-a6d9-b4159c70d949
# ╟─59e573f6-cb33-45bd-b54c-6f750833dddb
# ╠═12ab9845-c490-4b7e-845b-f58ee29786e1
# ╠═97c3ca0a-b254-4ee5-8ea0-c1295ac28183
# ╠═f5f5d6ed-5982-4ee9-b757-c3d36a8c9ddf
# ╠═5eb03efe-d38d-4098-9d8d-60d4e9fcf6c7
# ╟─7752ad2d-464e-4a6a-bf29-8cda5ce05d41
# ╠═e7d55336-155c-49c7-af5a-428175aea98d
# ╠═334d4c78-07e6-489c-9558-1fd429c0cce9
# ╠═8129e797-c070-49d1-8fdb-d8eeb0a7eff8
# ╠═9cf8c8ba-047c-47e4-9ca5-5c27c2472223
# ╟─b34cf39b-b300-440f-b76e-08035cec682c
# ╟─a5b6052f-a90c-45da-ad7d-8e516a962e1d
# ╟─b651d847-36f9-40d5-ad5d-f19762d67b9a
# ╠═6e2fc6eb-1e48-4141-8bc6-56257fa30a19
# ╟─90913574-f83e-4d66-bef8-cbdaafe78ebe
# ╠═bb68646c-7f13-4e80-a57f-aeef567188b5
# ╠═d909d3d1-947c-47a1-82cc-5317d9c75929
# ╠═0f38e6cc-27ce-4b69-bb89-e334d0386694
# ╠═6c89c478-a0a0-4d40-8af8-7e0777edc0d4
# ╠═bac9696b-b152-43fc-8db3-49e368471849
# ╠═aa285156-ca15-42b2-95c1-1b74f78ee9e9
# ╠═326c8685-e9b5-44b2-843a-a8dc010aa682
