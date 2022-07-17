### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ f0c66ca0-04de-11ed-2ebb-07fbe53e7327
begin
	using Pkg
	Pkg.activate()
	using XLSX
	using Plots
	using DataFrames
	using Statistics
	plotly()
end

# ╔═╡ 21abb737-5e83-452d-b850-3c1fb04b5060
begin
	Mₐ = 0.028964
	g = 9.80665
	R = 8.314472
	Rₐ = R / Mₐ
	Γ = 9.75e-3
	cₚₐ = 1006 # [J kg-1 K-1]
	Ω = 2pi / 3600 / 24
end

# ╔═╡ e044f5f0-b6f7-4ac9-bd48-d331c3726195
data = XLSX.readtable("Example 5.1 Analysis Rawinsonde Data.xlsx", "Sheet1"; first_row = 13)

# ╔═╡ ea0b98ab-15d9-40e8-8e64-759fbef94e08
begin
	ps = data[1][1] * 1e2
	ts = data[1][2] .+ 273.15
	ρs = ps ./ (Rₐ * ts)
end

# ╔═╡ 04aaeb62-1d57-4221-bb7e-e11581ebcab6
begin
	exppot = Rₐ/cₚₐ
	θ = ts .* (1e5 ./ ps).^exppot
end

# ╔═╡ 12d21f50-570d-447f-82e8-4b5c6d6f270c
function trapz(x, f)
	@assert length(f) == length(x)
	res = Vector{Float64}(undef, length(f)-1)
	for i in 1:length(f)-1
		res[i] = (f[i] + f[i+1]) / 2 * (x[i+1] - x[i])
	end
	res
end

# ╔═╡ dcb870f5-bb07-493c-97db-c3aaf1f0edb1
Δzs = trapz(ps, - 1 ./ (g .* ρs))

# ╔═╡ 0665bb0b-ac31-44a8-800d-89308ecbac00
function sums(vec; init = 0)
	res = fill(0., length(vec)+1)
	res[1] = init
	for (i, val) in enumerate(vec)
		res[i+1] = sum(vec[1:i])
	end
	res
end

# ╔═╡ 5693576d-625d-442d-820c-e85f79a0dd93
zs = sums(Δzs)

# ╔═╡ 6677a886-7449-4516-bb01-6da90e9ce38f
begin
	plot(plot(ps, zs, marker = :circle,title="p"), plot(ts, zs, marker = :circle,title="T"), plot(ρs, zs, marker = :circle,title="ρ"), label = "")
end

# ╔═╡ f54a4af4-484e-43c0-8b73-1dd63f63f5e8
begin
	plot(ts, zs, marker = :circle)
	plot!([(ts[1] - Γ, zs[1]), (ts[end] - Γ, zs[end])])
end

# ╔═╡ ee3e1e23-0b5b-4fb0-a5e6-c613e822d50b
plot(θ, zs, marker = :circle)

# ╔═╡ af7c3c76-9650-411c-8137-7e5b1c32f8e3
function forward_diff(z, θ)
	@assert length(z) == length(θ)
	res = Vector{Float64}(undef, length(z)-1)
	for i in 1:length(z)-1
		res[i] = (θ[i+1] - θ[i]) / (z[i+1] - z[i])
	end
	res
end

# ╔═╡ a92ae644-e223-45a3-8a4e-f85e5633e519
s = forward_diff(zs, θ) * g ./ ts[1:end-1]

# ╔═╡ 73860ad4-8cb8-4767-ac83-845b2b9e5af8
plot(s)

# ╔═╡ aa8208ab-952f-49c9-887a-3cda5c23570e
begin
	u_m = 5 # [m s-1]
	z_m = 10
	q_0 = 200 # [W m^2]
	z_0 = 0.5 # [m]
	T_0 = 300 # [K]
	p_0 = 101e2 # [Pa]
	k = 0.4
	a = 6.1
	b = 2.5
	ustar_0 = k * u_m / log(z_m / z_0) 
end

# ╔═╡ eb1637d5-15e2-4c12-ad59-b2536583a72c
hmix = 0.3 * ustar_0 / abs((2*Ω*sind(50)))

# ╔═╡ 9b814981-ff46-4fae-847a-6975a3fc845d
md"""
### Example 5.9
"""

# ╔═╡ c35c6962-c081-4406-b5e0-835678c598e4
wind_df = DataFrame(XLSX.readtable("Example 5.9. Measures of turbulence from 10 Hz data.xlsx", 1, first_row=14)...)

# ╔═╡ 0563bccd-f75d-438e-a9bd-6ab214b2f3fe
ubar = mean(wind_df[:, 2])

# ╔═╡ 626380f4-8f15-4e4e-a8b7-9264567cc625
variance = var(wind_df[:, 2])

# ╔═╡ d9071022-616f-496a-9100-4219a925f466
σᵤ = sqrt(variance)

# ╔═╡ 63a9d52c-afce-452f-8796-ef324fbab310
iᵤ = σᵤ / ubar

# ╔═╡ 1900c3b7-6c19-4c34-b22f-dcd49fa603c3
wind_df[:, :ut] = wind_df[:, 2] .- ubar

# ╔═╡ e9de7267-6fe1-4fe3-8615-304944d28f07
wind_df[:, :uvar] = wind_df.ut.^2

# ╔═╡ 2b6527dc-d074-4c93-a197-4ba54bc5493a
wind_df

# ╔═╡ 5e87312b-fe40-41a2-9289-3e2f83ad82c3
begin
	plot(wind_df[:, 1], wind_df[:, 2])
	plot!([wind_df[1, 1], wind_df[end, 1]], [ubar, ubar])
	plot!(wind_df[:, 1], sqrt.(wind_df.uvar), label = "std")
	plot!([wind_df[1, 1], wind_df[end, 1]], [σᵤ, σᵤ] .+ ubar)
	plot!([wind_df[1, 1], wind_df[end, 1]], -[σᵤ, σᵤ] .+ ubar)
end

# ╔═╡ 9c93cfe4-4d49-466f-8c44-2eae74a39714
md"""
### Example 5.10
"""

# ╔═╡ c874b57b-c4fc-4a50-a4fd-e8b862d8eb42
flux_df = DataFrame(XLSX.readtable("Example 5.10. Flux measurement with eddy correlation technique.xlsx", 1, first_row=10)...)

# ╔═╡ 8585421d-1897-4b61-8197-737ae3309841
wbar = mean(flux_df[:, 2])

# ╔═╡ f175b819-0716-4ce3-80fc-e7080f8b07a1
cbar = mean(flux_df[:, 3])

# ╔═╡ 6ee62ff6-589d-4509-be5f-ab82a95810b3
flux_df.wt = flux_df[:, 2] .- wbar

# ╔═╡ d9198969-bd5a-45dd-8449-82b55f31e847
flux_df.ct = flux_df[:, 3] .- cbar

# ╔═╡ d447ddfd-8f8b-426b-a8c3-4ee88259e5e7
begin 
	gr()
	plot(flux_df[:, 1], flux_df.wt, color = :red)
	plot!(twinx(), flux_df[:, 1], flux_df.ct)

end

# ╔═╡ 8e5506af-b4e9-43a7-afbe-c5cd9c9de5d7
flux = mean(flux_df.wt .* flux_df.ct) + cbar * wbar

# ╔═╡ 48590daf-846b-4530-b3ba-741bb0a629e2
getL(rho, cp, T0, ustar, q) = - rho * cp * T0 * ustar^3 / (k * g * q)

# ╔═╡ 8dec9c65-d1db-4449-80d0-23e82f543a95
ksi_0 = getL(1.2, cₚₐ, T_0, ustar_0, q_0) * z_m

# ╔═╡ b0ba7704-9fde-4469-a106-0d532d53a1a0
getPhi(ksi) = (1 - 16*ksi)^(-0.25)

# ╔═╡ Cell order:
# ╠═f0c66ca0-04de-11ed-2ebb-07fbe53e7327
# ╠═21abb737-5e83-452d-b850-3c1fb04b5060
# ╠═e044f5f0-b6f7-4ac9-bd48-d331c3726195
# ╠═ea0b98ab-15d9-40e8-8e64-759fbef94e08
# ╠═dcb870f5-bb07-493c-97db-c3aaf1f0edb1
# ╠═5693576d-625d-442d-820c-e85f79a0dd93
# ╠═6677a886-7449-4516-bb01-6da90e9ce38f
# ╠═f54a4af4-484e-43c0-8b73-1dd63f63f5e8
# ╠═04aaeb62-1d57-4221-bb7e-e11581ebcab6
# ╠═ee3e1e23-0b5b-4fb0-a5e6-c613e822d50b
# ╠═a92ae644-e223-45a3-8a4e-f85e5633e519
# ╠═73860ad4-8cb8-4767-ac83-845b2b9e5af8
# ╠═12d21f50-570d-447f-82e8-4b5c6d6f270c
# ╠═0665bb0b-ac31-44a8-800d-89308ecbac00
# ╠═af7c3c76-9650-411c-8137-7e5b1c32f8e3
# ╠═aa8208ab-952f-49c9-887a-3cda5c23570e
# ╠═eb1637d5-15e2-4c12-ad59-b2536583a72c
# ╟─9b814981-ff46-4fae-847a-6975a3fc845d
# ╠═c35c6962-c081-4406-b5e0-835678c598e4
# ╠═0563bccd-f75d-438e-a9bd-6ab214b2f3fe
# ╠═626380f4-8f15-4e4e-a8b7-9264567cc625
# ╠═d9071022-616f-496a-9100-4219a925f466
# ╠═63a9d52c-afce-452f-8796-ef324fbab310
# ╠═1900c3b7-6c19-4c34-b22f-dcd49fa603c3
# ╠═e9de7267-6fe1-4fe3-8615-304944d28f07
# ╠═2b6527dc-d074-4c93-a197-4ba54bc5493a
# ╠═5e87312b-fe40-41a2-9289-3e2f83ad82c3
# ╟─9c93cfe4-4d49-466f-8c44-2eae74a39714
# ╠═c874b57b-c4fc-4a50-a4fd-e8b862d8eb42
# ╠═8585421d-1897-4b61-8197-737ae3309841
# ╠═f175b819-0716-4ce3-80fc-e7080f8b07a1
# ╠═6ee62ff6-589d-4509-be5f-ab82a95810b3
# ╠═d9198969-bd5a-45dd-8449-82b55f31e847
# ╠═d447ddfd-8f8b-426b-a8c3-4ee88259e5e7
# ╠═8e5506af-b4e9-43a7-afbe-c5cd9c9de5d7
# ╠═8dec9c65-d1db-4449-80d0-23e82f543a95
# ╠═48590daf-846b-4530-b3ba-741bb0a629e2
# ╠═b0ba7704-9fde-4469-a106-0d532d53a1a0
