### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 09bea638-2dec-11ed-3d08-352e29bf3a20
begin
	using Pkg
	Pkg.activate("..")
	using Geodesy
	using PlutoUI
	using Rasters
	using Plots
end

# ╔═╡ e4ce71c2-f2ea-4643-a624-57b015af7bc4
outfile = "/home/tcarion/Documents/suffield/postprocess/flexpart_outputs/NH3_1321_1322_ctl10_20m/output/grid_conc_20140813214000.nc"

# ╔═╡ 70b4c0d3-f6d0-4008-b0f5-52fa1bcc801c
stack = RasterStack(outfile)

# ╔═╡ 43ef9f06-1d33-452a-b249-e92fdd501f4b
relpoint = (
	lat = convert(Float64, first(stack[:RELLAT1])), 
	lon = convert(Float64, first(stack[:RELLNG1]))
)

# ╔═╡ ec805ea3-f429-481b-b58f-531412202e07
spec = stack[:spec001_mr]

# ╔═╡ 148f3ea0-7c60-49e7-94cf-2a157cd3833b
horiz = view(spec,
	Ti(50),
	height=10,
	pointspec=1,
	nageclass=1
)

# ╔═╡ 85d094ec-e010-4a05-9adf-4441c6bcf711
lons = dims(horiz, :X) |> collect

# ╔═╡ 8948ae9b-b524-4665-8bf3-0d799b7a0306
Nlons = length(lons)

# ╔═╡ 99eee13b-63e8-492b-8c0d-94e9b102fba1
lats = dims(horiz, :Y) |> collect

# ╔═╡ ed207be9-a523-41c8-a7d3-10d020fcd9d7
Nlats = length(lats)

# ╔═╡ bc428aef-0ecd-4b17-8bd9-1bc3598b9799
lons_grid = lons * ones(Nlons)'

# ╔═╡ 61eaf9fa-8b1a-4fbf-9f7d-003c50581b1a
x_lla = LLA(50, 4)

# ╔═╡ c1e08e77-453e-455e-b96d-fcdda518557d
x_ecef = ECEF(x_lla, wgs84)

# ╔═╡ d9d09b4a-2d5e-4e5d-954b-60f3917d5ed5
origin_lla = LLA(relpoint...)

# ╔═╡ 5b42baf7-3d88-45bb-a5d9-5f55705f6d08
trans = ENUfromLLA(origin_lla, wgs84)

# ╔═╡ 7638047f-0f44-4121-a859-bc4ccaf290ac
begin
	# origin_lla = LLA(relpoint...)
	point_lla = LLA(-27.465933, 153.025900, 0.0)  # Central Station, Brisbane, Australia
	
	# Define the transformation and execute it
	# trans = ENUfromLLA(origin_lla, wgs84)
	point_enu = trans(point_lla)
end

# ╔═╡ a3a85e6f-e470-43a5-958f-294c6865a767
to_enu(lon, lat) = trans(LLA(lon=lon, lat=lat))

# ╔═╡ 5fb77d70-5a8f-4404-aa43-431e293aea42
coords_enu = [to_enu(lon, lat) for lon in lons, lat in lats]

# ╔═╡ 47cb3a9c-70df-4227-a62c-e0be38c99c91
xs = getproperty.(coords_enu, :e)

# ╔═╡ 3ddcec53-591c-4413-a9d4-94ff3058c9bc
ys = getproperty.(coords_enu, :n)

# ╔═╡ 37b2508a-ea3b-4f89-aa2b-6a0d8be9019f
contourf(xs, ys, Matrix(horiz))

# ╔═╡ ebcbf4e7-f3df-42d2-a8c7-96f8ecebb413
heatmap(horiz)

# ╔═╡ c8185e02-42cf-4223-aa05-98a94d5a896b
vcat(collect(walkdir("../flexpart_outputs"))...)

# ╔═╡ 969ae517-acd2-4ffe-a6ac-b33953834d3c


# ╔═╡ Cell order:
# ╠═09bea638-2dec-11ed-3d08-352e29bf3a20
# ╠═e4ce71c2-f2ea-4643-a624-57b015af7bc4
# ╠═70b4c0d3-f6d0-4008-b0f5-52fa1bcc801c
# ╠═43ef9f06-1d33-452a-b249-e92fdd501f4b
# ╠═ec805ea3-f429-481b-b58f-531412202e07
# ╠═148f3ea0-7c60-49e7-94cf-2a157cd3833b
# ╠═85d094ec-e010-4a05-9adf-4441c6bcf711
# ╠═8948ae9b-b524-4665-8bf3-0d799b7a0306
# ╠═99eee13b-63e8-492b-8c0d-94e9b102fba1
# ╠═ed207be9-a523-41c8-a7d3-10d020fcd9d7
# ╠═bc428aef-0ecd-4b17-8bd9-1bc3598b9799
# ╠═61eaf9fa-8b1a-4fbf-9f7d-003c50581b1a
# ╠═c1e08e77-453e-455e-b96d-fcdda518557d
# ╠═7638047f-0f44-4121-a859-bc4ccaf290ac
# ╠═d9d09b4a-2d5e-4e5d-954b-60f3917d5ed5
# ╠═5b42baf7-3d88-45bb-a5d9-5f55705f6d08
# ╠═a3a85e6f-e470-43a5-958f-294c6865a767
# ╠═5fb77d70-5a8f-4404-aa43-431e293aea42
# ╠═47cb3a9c-70df-4227-a62c-e0be38c99c91
# ╠═3ddcec53-591c-4413-a9d4-94ff3058c9bc
# ╠═37b2508a-ea3b-4f89-aa2b-6a0d8be9019f
# ╠═ebcbf4e7-f3df-42d2-a8c7-96f8ecebb413
# ╠═c8185e02-42cf-4223-aa05-98a94d5a896b
# ╠═969ae517-acd2-4ffe-a6ac-b33953834d3c
