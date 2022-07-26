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

# ╔═╡ ffcbe6ad-0a64-473b-bfe0-35f215b539d2
begin
	using Pkg
	Pkg.activate("..")
	using Rasters
	using PlutoUI
	using Plots
end

# ╔═╡ 1bdc3e20-651e-449e-b8d4-2722d894264b
using ColorTypes: N0f8

# ╔═╡ 8142b721-bd13-4f61-8255-e2e83a8aec54
using ImageShow, Images

# ╔═╡ 5fc7f00d-f7dd-4516-b0ae-70ae9a2bf50f
lat, lon = 50.255268752, -110.774045847

# ╔═╡ 519345ab-2291-40a1-b862-e54ce7e5e95a
tiffile = "2021-06-29-00 00_2021-06-29-23 59_Landsat_8_L2_True_color_low_8bit.tiff"

# ╔═╡ f60aa9aa-e568-4394-8607-2bca3b490986
satfile = joinpath("..", "images", "sat", tiffile)

# ╔═╡ d5700698-55c3-4a0c-9c16-63f28bcea2e7
# tifrast_unzoomed = permutedims(Raster(satfile), (2, 1, 3))
tifrast_unzoomed = Raster(satfile)

# ╔═╡ 285ad433-38d6-4fa8-bc1b-ce945cb804b8
begin
	satlons_nz = dims(tifrast_unzoomed, X) |> collect
	satlats_nz = dims(tifrast_unzoomed, Y) |> collect
end

# ╔═╡ 9c0a55a3-13fa-47fc-88db-7fd488e213c5
md"""
Zoom = lons: $(@bind satxrange RangeSlider(1:length(satlons_nz))) lats: $(@bind satyrange RangeSlider(1:length(satlats_nz)))
"""

# ╔═╡ 353c1ba2-8c2c-4333-ab75-8967be43da59
begin
	satlons = satlons_nz[satxrange]
	satlats = satlats_nz[satyrange]
end

# ╔═╡ 3030226a-6bb3-4b1c-b92a-f5dc06dd18be
(satlons[2] - satlons[1]) * 111e3

# ╔═╡ 4a0bcebb-8860-4a14-9f8c-966501ea4735
tifrast = reinterpret.(N0f8, view(tifrast_unzoomed, X(satxrange), Y(satyrange)))

# ╔═╡ 5f0c6614-066a-4ebf-8e3c-ac1ab40ad617
tifrgb = Rasters.DimArray(RGB.(tifrast[:,:,1], tifrast[:,:,2], tifrast[:,:,3]) |> Matrix, (X(satlons_nz[satxrange]), Y(satlats_nz[satyrange])));

# ╔═╡ 3fd6bf3c-04f6-44a9-ba49-ef4a8cb8a328
tifrgb |> Matrix |> size

# ╔═╡ c5eece3d-451e-46ca-9640-8d62aa411044
tifmatrix = permutedims(tifrgb |> Matrix, (2, 1))
# tifmatrix = tifrgb |> Matrix

# ╔═╡ bde10fa6-bb86-4c63-a4c4-892d73bfa2ca
tifrgb |> Matrix |> size

# ╔═╡ dac06c23-f38f-4c4c-ad8d-2063f7980f99
tifmatrix |> size

# ╔═╡ 97394a74-8fb0-432a-acb8-b8f2b32fa31e
satlons |> length

# ╔═╡ bbc41e57-661c-45d5-b7b7-7a2948c2fca6
satlats |> length

# ╔═╡ 82621b9c-b516-4f86-afe9-f958c83d2771
begin
	plot(satlons[1:16], satlats[1:5], colorview(RGB, tifmatrix)[1:16, 1:5])
	plot!((lon, lat), marker = :star, markersize= :6, label= false)

end

# ╔═╡ 219d1f4d-7411-4d3b-9c00-2c0d3eb6580e


# ╔═╡ eb4be2b8-a9be-4e38-b525-5c1bdccc013b
tifrgb[:,:] |> typeof

# ╔═╡ Cell order:
# ╠═ffcbe6ad-0a64-473b-bfe0-35f215b539d2
# ╠═1bdc3e20-651e-449e-b8d4-2722d894264b
# ╠═8142b721-bd13-4f61-8255-e2e83a8aec54
# ╠═5fc7f00d-f7dd-4516-b0ae-70ae9a2bf50f
# ╠═519345ab-2291-40a1-b862-e54ce7e5e95a
# ╠═f60aa9aa-e568-4394-8607-2bca3b490986
# ╠═d5700698-55c3-4a0c-9c16-63f28bcea2e7
# ╠═3030226a-6bb3-4b1c-b92a-f5dc06dd18be
# ╠═285ad433-38d6-4fa8-bc1b-ce945cb804b8
# ╟─9c0a55a3-13fa-47fc-88db-7fd488e213c5
# ╠═353c1ba2-8c2c-4333-ab75-8967be43da59
# ╠═4a0bcebb-8860-4a14-9f8c-966501ea4735
# ╠═5f0c6614-066a-4ebf-8e3c-ac1ab40ad617
# ╠═3fd6bf3c-04f6-44a9-ba49-ef4a8cb8a328
# ╠═c5eece3d-451e-46ca-9640-8d62aa411044
# ╠═bde10fa6-bb86-4c63-a4c4-892d73bfa2ca
# ╠═dac06c23-f38f-4c4c-ad8d-2063f7980f99
# ╠═97394a74-8fb0-432a-acb8-b8f2b32fa31e
# ╠═bbc41e57-661c-45d5-b7b7-7a2948c2fca6
# ╠═82621b9c-b516-4f86-afe9-f958c83d2771
# ╠═219d1f4d-7411-4d3b-9c00-2c0d3eb6580e
# ╠═eb4be2b8-a9be-4e38-b525-5c1bdccc013b
