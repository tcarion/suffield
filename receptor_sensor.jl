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
	Pkg.activate(".")
	using PlutoUI
	using Flexpart
	using Rasters
	using Plots
	include("scripts/read_sensors.jl")
	include("scripts/read_recept.jl")
	plotly()
end

# ╔═╡ 2b89e6d5-b01d-4a8c-bf6d-bd38ed19bc1a
@bind fppath Select(filter(isdir, readdir("flexpart_outputs", join = true)))

# ╔═╡ 89bf5e33-7e0b-49bd-8fbc-2570598d97de
@bind rectype Select(["conc", "pptv"], default = "pptv")

# ╔═╡ f44fa436-b42e-4016-b12c-19f866cbecb7
molarmass = 17 # [g/mol]

# ╔═╡ 7b33bf6e-9292-4a15-a992-3438b44893e9
fpdir = FlexpartDir(fppath)

# ╔═╡ 528d805e-b581-4f3d-a7fe-30f763e2ff42
stack = RasterStack(OutputFiles(fpdir)[1].path)

# ╔═╡ 8fe1f0b1-81bd-4fee-a16a-84dff9fca1c0
spec001_mr = stack[:spec001_mr]

# ╔═╡ 51d4f8ee-6b5f-4ab8-a97b-ba83c6051488
receptor = read_receptor(fpdir; rectype = rectype)

# ╔═╡ 7165bbd9-c137-4c17-b912-a0ca4e01707a
sensor = read_sensors()

# ╔═╡ 0f48bd0e-f0b4-4c69-ad72-f2b88be33dc5
@bind timerange RangeSlider(1: length(receptor.time))

# ╔═╡ 5b54ef9b-e5e2-4dab-8ff4-f99533b7321e
conctoppm(c) = c * 8.314472 * (288) / (molarmass * 1e5) * 1e6

# ╔═╡ b174bf28-6f8c-4b4c-ba18-fbef38c6be70
begin
if rectype == "conc"
	receptor.ppm = conctoppm.(receptor.conc .* 1e-9)
elseif rectype == "pptv"
	receptor.ppm = receptor.pptv * 1e6
end
newreceptor = receptor
end

# ╔═╡ 06381ed1-1c64-4f6f-ab27-f038cb83b474
begin
	plot(newreceptor.time[timerange], newreceptor.ppm[timerange], label = "receptor",
		title="NH3 concentration",
		ylabel = "concentration [ppmv]",
		xrotation = 8,
		marker=:dot
	)
	plot!(sensor.time, sensor.ppm, label = "sensor")
end

# ╔═╡ 3ab85225-83f9-4593-a695-e468ae13bbe6
conc = filter(x -> !(x ≈ 0),  receptor.conc)  * 1e-9

# ╔═╡ 6886b692-5536-4ce7-af75-615443d69353
conctoppm.(conc)

# ╔═╡ Cell order:
# ╠═3d72aa34-f399-11ec-0c2d-73517f7f39b6
# ╠═2b89e6d5-b01d-4a8c-bf6d-bd38ed19bc1a
# ╠═89bf5e33-7e0b-49bd-8fbc-2570598d97de
# ╠═f44fa436-b42e-4016-b12c-19f866cbecb7
# ╠═7b33bf6e-9292-4a15-a992-3438b44893e9
# ╠═528d805e-b581-4f3d-a7fe-30f763e2ff42
# ╠═8fe1f0b1-81bd-4fee-a16a-84dff9fca1c0
# ╠═51d4f8ee-6b5f-4ab8-a97b-ba83c6051488
# ╠═b174bf28-6f8c-4b4c-ba18-fbef38c6be70
# ╠═7165bbd9-c137-4c17-b912-a0ca4e01707a
# ╠═0f48bd0e-f0b4-4c69-ad72-f2b88be33dc5
# ╠═06381ed1-1c64-4f6f-ab27-f038cb83b474
# ╠═5b54ef9b-e5e2-4dab-8ff4-f99533b7321e
# ╠═3ab85225-83f9-4593-a695-e468ae13bbe6
# ╠═6886b692-5536-4ce7-af75-615443d69353
