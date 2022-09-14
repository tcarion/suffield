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

# ╔═╡ 64c12370-4bf5-49fc-b62d-909ab1ec6d07
begin
	using Pkg
	Pkg.activate("..")
	using ATP45
	using PlutoUI
	using Plots
end

# ╔═╡ 442208d7-bbde-4fde-a5d2-978735c9d5d5
plotly()

# ╔═╡ 3cc8dc79-3b87-41a7-b0a6-19b1ee600cbc
@bind winddir_slide Slider(0:5:360, show_value = true, default = 5) 

# ╔═╡ 42392e68-999d-448c-90b5-a675c610fd95
@bind windspeed_slide Slider(0:15, show_value = true, default = 10) 

# ╔═╡ da06577e-41f3-429c-937d-e385949181b7
relpoint = [50., 4.]

# ╔═╡ 29ae638e-e695-4e82-9055-77ae58ffce47
wind = WindDirection(windspeed_slide, winddir_slide)

# ╔═╡ a8a3b6d2-9286-47c2-9d01-7e714ae6bd55
input = Atp45Input(
	[relpoint],
	wind,
	:BOM,
	:simplified,
	ATP45.Stable
)

# ╔═╡ 754b768e-c147-497d-9e89-d1d60c169386
result = run_chem(input)

# ╔═╡ a3c65836-6eb1-4e7f-8f64-e5f518916ada
begin
	# plot(xlim = [-10, 10], ylim = [-10, 10])
	plot(aspect_ratio = 1.)
	resultplot!(result)
	plot!(wind, w_origin = result.input.locations[1], w_normalize = true, w_scale = 0.1)
end

# ╔═╡ d2ad2c1e-66e7-424a-9f9b-b435f3b1e843
sqrt(10^2 + 10^2)

# ╔═╡ Cell order:
# ╠═64c12370-4bf5-49fc-b62d-909ab1ec6d07
# ╠═442208d7-bbde-4fde-a5d2-978735c9d5d5
# ╠═3cc8dc79-3b87-41a7-b0a6-19b1ee600cbc
# ╠═42392e68-999d-448c-90b5-a675c610fd95
# ╠═da06577e-41f3-429c-937d-e385949181b7
# ╠═29ae638e-e695-4e82-9055-77ae58ffce47
# ╠═a8a3b6d2-9286-47c2-9d01-7e714ae6bd55
# ╠═754b768e-c147-497d-9e89-d1d60c169386
# ╠═a3c65836-6eb1-4e7f-8f64-e5f518916ada
# ╠═d2ad2c1e-66e7-424a-9f9b-b435f3b1e843
