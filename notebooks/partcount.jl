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

# ╔═╡ f2525124-0742-11ed-33b3-21dad618fa03
begin
	using Pkg
	Pkg.activate(".")
	using XLSX
	using PlutoUI
	using DataFrames
	using Unitful
	using Plots
	plotly()
end

# ╔═╡ a806199e-1428-4646-a032-3eb27e6ceff3
cd("..")

# ╔═╡ 4250019e-87b4-44b2-a256-bfe0cd3503d1
md"""
#### File loading
"""

# ╔═╡ cd0986f3-19a4-4e40-a7ac-ca1a8ccf37bb
xlfile = "sensors_ds/Aerosol_SiteA_release.xlsx"

# ╔═╡ 41ba81fd-c598-43b6-b276-9da82c6e9f52
part_sizes = [0.3, 0.4, 0.5, 0.65, 0.8, 1., 1.6, 2, 3., 4., 5., 7.5, 10, 15, 20]

# ╔═╡ 2465aea6-de54-4b1a-b8e8-1e63c5b3d2fe
fsizes = Symbol.(replace.("s" .* string.(part_sizes), "." => "_"))

# ╔═╡ a3de0480-0562-4fe3-ae0f-39b7590e25d8
colnames = [
	:date, :julia, :time_local, :time_utc, fsizes..., :t, :RH, :u
];

# ╔═╡ ca328a49-60e0-40f1-b5c6-7a930d9c81e2
@bind sheet Select(XLSX.sheetnames(XLSX.readxlsx(xlfile)), default = "1808_J4230 MS")

# ╔═╡ 9e5fafee-5f7f-4ffc-949d-2f02cdb5d158
df = DataFrame(XLSX.readtable(xlfile, sheet; first_row = 4, column_labels = colnames)...)

# ╔═╡ 5ac7a6a3-6280-491a-acba-374ac3a585d2
nrow = 2;

# ╔═╡ f3632302-f34d-4ab4-8c59-d38a85f49fc1
row = df[nrow, :];

# ╔═╡ 772888c0-fea8-4bd7-9a18-3232608b01ea
begin 
	parts = row.s0_3 * u"1/m^3"
	u = row.u
	t = row.t
	size = 0.3 * 1e-6u"m"
end

# ╔═╡ f9bfcffc-24c8-4302-8ea2-f6401306028b
md"""
#### Concentration calculation
"""

# ╔═╡ 620dcd5b-625b-4ef3-ab3b-76691d580814
D = size

# ╔═╡ a9f2fa0f-1e2f-46a4-a466-d05e7c59f036
md"""
We assume spherical particles of diameter $D$ = $(uconvert(u"μm", D))
"""

# ╔═╡ f62bd87a-7b20-4675-908f-58c0526ee176
md"""
The volume $V$ is:
"""

# ╔═╡ 5d6708e2-43d8-4802-a5d8-2fbd823f835c
V = 4pi * (D/2)^3 / 3

# ╔═╡ a2819bde-ed27-41fe-8d1a-499348bcc16f
md"""
The density $\rho_{ms}$ of the Methyl Salicylate is 1.174 [g/cm³]
"""

# ╔═╡ 2f715736-2554-4459-a193-5c47044bd57c
ρₘₛ = 1.174u"g/cm^3"

# ╔═╡ ed52139c-dcb7-49db-93e5-6be4df87400c
md"""
The mass of each particle is:
"""

# ╔═╡ a289bba8-e18d-4736-8f55-c9a686e906a6
mₘₛ = uconvert(u"g", V * ρₘₛ)

# ╔═╡ 40bd09a2-4a4b-458f-957f-038f62f5d17f
md"""
The final concentration is the individual particle mass times the number of particles per m³:
"""

# ╔═╡ 51fb0170-d869-40d1-a308-5194b964b607
c = uconvert(u"mg/m^3", mₘₛ * parts)

# ╔═╡ c7dc91a9-0416-4bda-abb7-8668fa748501
md"""
#### Size distribution
"""

# ╔═╡ 439d0e32-e573-4ea3-83b5-f69622c86cd1
md"""
From the GRIMM PASS spectrometer documentation, we get the sampling flow $Q_s$ = 1.2 [L/min]
"""

# ╔═╡ 58782976-bb97-47ff-a1dd-f15043c5a0af
Qₛ = 1.2 * 1e-3u"m^3/minute"

# ╔═╡ 60c61b54-4ae8-46c5-b3af-94885d96bce0
partsnums = row[fsizes] |> collect

# ╔═╡ d4553fee-91fc-425e-8738-74af33686f18
plot(string.(fsizes), partsnums, marker=:dot)

# ╔═╡ 0d09fb54-6cd8-4b1b-bd90-a95581e11e46
plot(string.(fsizes), partsnums, yaxis=(:log10, [0.5, :auto]), marker=:dot, yticks = [10^i for i in 0:7], ylims=[0, 10^8])

# ╔═╡ a26ac087-b696-4bdd-908a-33c5f122bd7b
logmean(a, b) = 10^((log10(a) + log10(b)) / 2)

# ╔═╡ 036c4756-d653-47b0-b86d-614639277689
begin
	perbin = Vector{Float64}(undef, length(part_sizes))
	logmeans = Vector{Float64}(undef, length(part_sizes))
	for i in 1:length(part_sizes)-1
		logmeans[i] = logmean(part_sizes[i+1], part_sizes[i])
		perbin[i] = partsnums[i] - partsnums[i+1]
	end
	perbin[end] = partsnums[end]
	logmeans[end] = part_sizes[end]
	replace!(x -> x <= 0 ? 0.0001 : x, perbin)
end

# ╔═╡ 283664dd-7537-4a84-b991-d483144c72a7
plot(logmeans, replace(x -> x <= 0 ? 0.0001 : x, perbin),
	marker = :dot,
	yscale = :log10
)

# ╔═╡ ccf09210-e140-4a99-8fc5-c1d22debf7ff
function massconc(size, partnum, rho = 1.174)
	D = size
	V = 4pi * (D/2)^3 / 3
	m = V * rho
	m * partnum
end

# ╔═╡ f0b8adb5-25f8-4689-8c05-e278c23557b0
concs = massconc.(logmeans * 1u"μm", perbin * 1u"1/m^3", ρₘₛ) .|> u"mg/m^3"

# ╔═╡ 9bb39974-86d6-4734-af62-19e1b6377a8a
float.(concs)

# ╔═╡ d0994e67-1bc9-4c9d-9df7-8d3653aacfc6
plot(logmeans, ustrip.(concs), marker = :dot)

# ╔═╡ 0fd5a423-2d37-40ff-bc5b-89daad5a7d89
totalconc = sum(concs)

# ╔═╡ Cell order:
# ╠═f2525124-0742-11ed-33b3-21dad618fa03
# ╟─a806199e-1428-4646-a032-3eb27e6ceff3
# ╟─4250019e-87b4-44b2-a256-bfe0cd3503d1
# ╠═cd0986f3-19a4-4e40-a7ac-ca1a8ccf37bb
# ╠═41ba81fd-c598-43b6-b276-9da82c6e9f52
# ╠═2465aea6-de54-4b1a-b8e8-1e63c5b3d2fe
# ╠═a3de0480-0562-4fe3-ae0f-39b7590e25d8
# ╠═ca328a49-60e0-40f1-b5c6-7a930d9c81e2
# ╠═9e5fafee-5f7f-4ffc-949d-2f02cdb5d158
# ╠═5ac7a6a3-6280-491a-acba-374ac3a585d2
# ╠═f3632302-f34d-4ab4-8c59-d38a85f49fc1
# ╠═772888c0-fea8-4bd7-9a18-3232608b01ea
# ╟─f9bfcffc-24c8-4302-8ea2-f6401306028b
# ╟─a9f2fa0f-1e2f-46a4-a466-d05e7c59f036
# ╟─620dcd5b-625b-4ef3-ab3b-76691d580814
# ╟─f62bd87a-7b20-4675-908f-58c0526ee176
# ╠═5d6708e2-43d8-4802-a5d8-2fbd823f835c
# ╟─a2819bde-ed27-41fe-8d1a-499348bcc16f
# ╠═2f715736-2554-4459-a193-5c47044bd57c
# ╟─ed52139c-dcb7-49db-93e5-6be4df87400c
# ╠═a289bba8-e18d-4736-8f55-c9a686e906a6
# ╟─40bd09a2-4a4b-458f-957f-038f62f5d17f
# ╠═51fb0170-d869-40d1-a308-5194b964b607
# ╟─c7dc91a9-0416-4bda-abb7-8668fa748501
# ╟─439d0e32-e573-4ea3-83b5-f69622c86cd1
# ╠═58782976-bb97-47ff-a1dd-f15043c5a0af
# ╠═60c61b54-4ae8-46c5-b3af-94885d96bce0
# ╠═d4553fee-91fc-425e-8738-74af33686f18
# ╠═0d09fb54-6cd8-4b1b-bd90-a95581e11e46
# ╠═036c4756-d653-47b0-b86d-614639277689
# ╠═283664dd-7537-4a84-b991-d483144c72a7
# ╠═f0b8adb5-25f8-4689-8c05-e278c23557b0
# ╠═9bb39974-86d6-4734-af62-19e1b6377a8a
# ╠═d0994e67-1bc9-4c9d-9df7-8d3653aacfc6
# ╠═0fd5a423-2d37-40ff-bc5b-89daad5a7d89
# ╠═a26ac087-b696-4bdd-908a-33c5f122bd7b
# ╠═ccf09210-e140-4a99-8fc5-c1d22debf7ff
