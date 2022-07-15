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

# ╔═╡ 206febfe-ba37-11ec-0f21-ed03f153bcab
begin
	using Pkg
	Pkg.activate(".")
	using PlutoUI
	using DataFrames
	using CSV
	using CoolProp
	using Gadfly
	using Dates
	using Rasters
	using Plots
	using Flexpart
	df = DataFrames
end


# ╔═╡ 49b230de-26e3-4e25-9030-c2710a6907cc
md"""
## Introduction
This document is intended to give an overview of how the air dispersion modeling for the Suffield experiment has been pre-processed for the FLEXPART model and show some quick results of the simulations.
"""

# ╔═╡ 47407d00-4444-4b28-9588-1ba68393c060
md"""
## The releases file
First, all the gas releases found in the records of the experiment have been compiled in one [Google Sheet file](https://docs.google.com/spreadsheets/d/1gfNnfvlRbbryq2SxO3ti9CRxGw-ul4oiO6qlj-C1kBw/).
"""

# ╔═╡ 9dc033f5-2843-4d01-8b3c-b1cebda97a34
md"""
The **first sheet** contains all the required **information about the releases** (species, start and stop, quantity...). A comment is added if some information was ambiguous in the records and explains how the issue is addressed.
"""

# ╔═╡ 88f578e0-e4e8-463c-af62-68bfa670a40c
releases = DataFrame(CSV.File("releases_ds/releases.csv"))

# ╔═╡ 946af5a2-b69d-410f-8ab2-ab4e6296eb39
md"""
The **second sheet** contains some additional **information about the species**
"""

# ╔═╡ 76a9d47d-0bc8-4d19-9016-5ca0a11a483d
species = DataFrame(CSV.File("releases_ds/species.csv"))

# ╔═╡ 9bfe58a6-d0a5-4334-9001-88f699b28940
md"""
## Pre-processing of the releases
FLEXPART needs to know the mass of the specie that has been released. The gas releases have been originally recorded by 2 distinct means:
1. Mass difference of the tank after and before the release.
2. Flow rate in L/min.
"""

# ╔═╡ 75895285-efea-4a5a-8d51-2e97a181ac6d
md"""
The first case is quite straightforward since the mass is directly accessible. We can see below all the releases for which the mass is available:
"""

# ╔═╡ 2d7ddb42-bf0c-41d1-bfa9-e93331589722
mass_releases = dropmissing(releases, :mass)

# ╔═╡ b7cdb553-1b47-416f-9b85-729865c54f3f
md"""
The second case requires some manipulations. To calculate the mass, we need the density of the gas. It is calculated with the following assumptions:
- The temperate is ``303K``. This is (quite arbitrarily) chosen by looking at the overall temperature during the experiment.
- For the pressure we take the pressure in the tank that has been recorded during the experiment. Below is an example of how the density is calculated for one of the release:
"""

# ╔═╡ 5b2549d1-a5e2-4303-b8ae-f1ce1d44fe24
begin
	ch4_ex = releases[10, :]
	# We find the CAS number because CoolProp needs it to identify the specie.
	cas = first(df.subset(species, :code => x -> x .== ch4_ex.species))[:CAS]
	p = ch4_ex[:pressure] * 6894.76 # psi -> Pa
    T = 303 # K
	# PropsSI is a function from the CoolProp package that gives the state properties for the requested component.
	density = PropsSI("D", "P", p, "T", T, cas)
	md"""
	**density = $(round(density, digits = 4))``[kg \cdot m^{-3}]``**
	"""
end

# ╔═╡ 98499abc-28e4-4c4b-b6d5-82c544b7787a
md"""
By applying this to all the flow releases and dropping some of the releases where information is missing, we obtain a Dataset that is ready to be converted into FLEXPART releases syntax (which won't be specified here):
"""

# ╔═╡ 0f127fe0-0b48-4d96-9f55-049c474350a8
valid_releases = DataFrame(CSV.File("releases_ds/valid_releases.csv"))

# ╔═╡ c11768be-d76f-471b-93e0-a12ec99a72a5
md"""
From this dataset we can plot a time series of the released quantities for each specie (the x-axis corresponds to the start time of the release): 
"""

# ╔═╡ 52102e12-9b7f-42d9-ab87-2fd2b6dbb6e1
md"""
We can also plot any individual specie:
"""

# ╔═╡ 9c830b44-22fe-47a3-8e54-93246948581e
function plotmass(rel)
    xticks = DateTime(2014, 08, 11):Dates.Hour(12):DateTime(2014,08,20)
    # xticks = [DateTime(2014, 08, 11), DateTime(2014,08,20)]
    Gadfly.plot(rel, 
        x=:startdt, y=:mass,
        color=:species, Geom.point, 
        Scale.x_continuous(labels=x -> Dates.format(x, "yyyy-mm-ddTHH:MM")),
        Guide.xticks(ticks=xticks, orientation=:vertical, label=true),
        Guide.yticks(ticks=0.:0.5:5.5, label=true),
        Guide.xlabel("Start date"),
        Guide.ylabel("Mass"),
        Guide.title("Time series of the released mass for each specie"),
        Theme(background_color="white"),
        )
end

# ╔═╡ c938f980-7f7f-40a5-ab29-686c37dac913
plotmass(valid_releases)

# ╔═╡ cebe0897-e926-4249-bf0d-4993e47d902f
plotmass(df.subset(valid_releases, :species => x -> x .== "CH4"))

# ╔═╡ ce4ee8fe-d9cd-4178-92c0-e00dbd5b25f5
md"""
## Source parameters
"""

# ╔═╡ c2b0d28a-b32c-442e-9701-6e18c12eb115
md"""
The source is considered as a point source located at:
"""

# ╔═╡ 08bcc54d-0cd5-4c80-b13f-4a36e4bb392e
rellon, rellat = -110.774048, 50.2552681;

# ╔═╡ fdd0e08c-377a-48f3-a7e3-3d3bb700da84
md"""
at height (above the ground):
"""

# ╔═╡ b0d308c2-aefd-4ab7-a144-be9a52151d4c
height = 1.5;

# ╔═╡ 2a7e337f-1724-4d27-92f8-7f3c333cdf35
md"""
## Simulation results
FLEXPART outputs file are in **NetCDF format**. Here we use `Rasters.jl` to read and process the files, but similar API's exist in other language (e.g. NetCDF files can be read with `xarray` in python).
"""

# ╔═╡ b8f36b6f-bb56-455f-abc2-e26ff5c484b8
md"""
A NetCDF file is basically divided into **Dimensions**, **Variables** (or **Layers**) and **Metadata**. We can easily see them for the FP outputs:
"""

# ╔═╡ 7f203bac-93bd-4ce5-ae2b-166f8bf70faf
begin
	outfile_path = joinpath("flexpart_outputs", "NH3_190821/output/grid_conc_20140818190000.nc")
	fpoutput = RasterStack(outfile_path)
end

# ╔═╡ ba866f25-58ed-47ce-b18b-c8866ea66141
stackmeta = fpoutput.metadata

# ╔═╡ 0e0f21db-39e9-4b43-a4be-465af7633312
md"""
The output we will consider here is the result of the simulation for the releases of CH4.
"""

# ╔═╡ 38a6e3b2-d30d-4742-ba95-e99874d14be3
md"""
Let's discuss the more important variables and dimensions:
##### Dimensions
- `X` -> longitudes
- `Y` -> latitudes
- `Ti` -> Time
- `Dim{:height}` -> vertical dimension
- `Dim{:pointspec}` -> contains each separated release
##### Variables
- The most relevant variable is `:spec001_mr` which corresponds to the mass concentration
"""

# ╔═╡ b96902c0-e6bd-4064-bf39-f5c031036866
md"""
We can **access a specific variable** and see which dimensions it depends on:
"""

# ╔═╡ 7cbfbdfe-aa2d-4083-8b3e-a72db987854f
conc = fpoutput[:spec001_mr]

# ╔═╡ 634a7ede-f4a0-406f-ba0c-601ff77ff6c9
md"""
To get the **values of a dimension as a Vector**:
"""

# ╔═╡ 68106a40-295b-410f-b980-cc79fcc2ac22
heights = dims(conc, Dim{:height}) |> collect

# ╔═╡ 64789193-ad38-4013-971a-5d50d8050af8
longitudes = dims(conc, X) |> collect

# ╔═╡ 37ac8ebe-4ad3-44fe-88be-92a2a3c6e5ce
latitudes = dims(conc, Y) |> collect

# ╔═╡ 4a45c0ae-43e2-405e-b5d4-0e67b81830aa
times = dims(conc, Ti) |> collect

# ╔═╡ 32f68603-692e-4115-9fab-09821ffc9bf5
relindex = dims(conc, Dim{:pointspec}) |> collect

# ╔═╡ eafec9dd-99dc-4689-99b4-0ac3aee2af51
begin
	# plotabledates = DateTime(2014,8,11,22,00):Dates.Minute(15):DateTime(2014,8,12,4) |> collect
	plotabledates = dims(conc, Ti)
	dateselect = [d => Dates.format(d, "yyyymmddTHH:MM:SS") for d in plotabledates]
end;

# ╔═╡ 0030d778-f912-4453-9aac-1cafe321a540
md"""
We can **slice the data through specific dimensions** with the following syntax. Here we want the spatial concentration at $(@bind heighttoplot Select(heights))m for the release nbr $(@bind reltoplot Scrubbable(relindex))) at $(@bind datetoplot Select(dateselect)):
"""

# ╔═╡ 9b693aca-2261-48fe-b105-94b4bf8a7133
twodconc = view(conc, 
	Ti(At(datetoplot)),
	Dim{:height}(At(heighttoplot)),
	Dim{:pointspec}(reltoplot),
	Dim{:nageclass}(1),
)

# ╔═╡ c4694912-a1e4-47aa-b8f4-e2749e45e4a9
md"""
We use the `view` function so **the data is not directly loaded into memory**. 
"""

# ╔═╡ e1d47d7c-e9c7-40dd-9b9f-d75df636e5b1
md"""
We can also see the metadata related to the considered variable:
"""

# ╔═╡ ec470e9a-2655-44bc-936c-dbb3399a46ab
concmeta = metadata(conc)

# ╔═╡ 94465487-d387-4b1d-86be-1b7c53c1dc72
md"""
##### Plotting
Now we can easily plot the data we read from the file and add some information on the plot using the metadata of the variable (`refdims` allows to get the value of the dimensions that have been sliced):
"""

# ╔═╡ c2fb94a2-e4a3-41ed-b56f-a1456612417b
function plotconc(conc)
	longitudes = dims(conc, X) |> collect
	latitudes = dims(conc, Y) |> collect
	concmeta = metadata(conc)
	title = "$(concmeta[:long_name]) concentration at $(refdims(conc, Ti)[1]) - $(refdims(conc, Dim{:height})[1])m"
	Plots.heatmap(longitudes, latitudes, Matrix(conc)', 
		c = :jet,
		title = title,
		colorbar_title="$(concmeta[:units])",
		xlabel = "longitudes",
		ylabel = "latitudes",
	)
end

# ╔═╡ e5f548bc-d857-461a-8292-811d0eb42f6d
plotconc(twodconc)

# ╔═╡ 0f30699a-0f51-4ccf-ad57-9448a9c4530a
md"""
Now let's plot **the vertical concentration** for $(datetoplot) at a specific location lon = $(@bind loclon Scrubbable(longitudes, default = -111.4)), lat = $(@bind loclat Scrubbable(latitudes, default = 50.4)). We can also select for which releases we want to plot.
"""

# ╔═╡ 381f848e-5944-47be-a872-57789f997a55
heightatloc = fpoutput[:ORO][X(Near(loclon)), Y(Near(loclat))]

# ╔═╡ ab08360b-6f45-4095-98f1-9e34e17b9d5f
let
	pconc = plotconc(twodconc)
	Plots.plot!(pconc, (loclon, loclat), marker = :circle, label = "vertcut")
end

# ╔═╡ 6467821f-5151-4f6c-9bbe-0342a2557aea
md"""
relvertcut = $(@bind relvertcut RangeSlider(1:length(relindex)))
"""

# ╔═╡ a764002c-fc81-4b8d-92a6-f71c61548494
md"""
We can also observe the plume moving by creating a simple animation:
"""

# ╔═╡ 2f80013d-7570-40e3-8cf1-dfda09451c12
@gif for date in DateTime(2014,8,11,22,00,00):Dates.Minute(15):DateTime(2014,8,12,5,00,00)
	toplot = view(conc, 
		Ti(At(date)),
		Dim{:height}(At(50.)),
		Dim{:pointspec}(2),
		Dim{:nageclass}(1),
	)
	Plots.plot(longitudes, latitudes, Matrix(toplot)', st = :heatmap, c = :jet,
		title = "$(concmeta[:long_name]) concentration at $(refdims(toplot, Ti)[1])"
	)
end

# ╔═╡ f0f6ebcf-3b27-4ce6-9341-60d7abdeb5e0
md"""
If we want to see **all the releases**, we can write a function that will sum the arrays along the `Dim{:pointspec}` dimension for a specific time and height: 
"""

# ╔═╡ cb90ee77-ac74-480c-9511-53f69530bf9f
function sum_releases(conc, date, height)
	viewed_conc = view(conc, 
		Ti(At(date)),
		Dim{:height}(At(height)),
		Dim{:nageclass}(1),
	)
	sumed = sum(viewed_conc; dims = Dim{:pointspec})
	sumed[:,:,1]
end

# ╔═╡ 4ad360a0-9438-4a16-8ea3-aece3bc16603
sumed_conc = sum_releases(conc, datetoplot, heighttoplot)

# ╔═╡ 1642d9df-68a0-495c-b82d-20209e717e45
plotconc(sumed_conc)

# ╔═╡ d18dddc7-a3fa-4e3e-99a6-163162c11fc3
md"""
We can see that the spatial dispersion of the plume is similar to the case where we only ploted the second release (probably because the 3 releases that have occured at this time are very closed to each other). However, we observe that the concentration is higher.
"""

# ╔═╡ a80b764a-794a-4c83-877d-e8de75b0c7c2
md"""
##### Some additional data handling:
"""

# ╔═╡ 912986f2-d119-41ec-80f3-54215c3e8e62
md"""
Getting some of the release comments:
"""

# ╔═╡ 2d15d793-5061-4a24-ab75-8c0a8b00f0eb
md"""
The **number** after "RELEASE" corresponds to the **:id column** in the releases dataset
"""

# ╔═╡ e0a9d60c-f3a5-4853-9431-a043ce980622
getcomment(data, pointspec) = reduce(*, data[:RELCOM][:, pointspec] |> collect)

# ╔═╡ 468d54cd-7f8f-4294-b557-c6624dd6ddf2
begin
	labels = [getcomment(fpoutput, ind)[1:10] for ind in relvertcut]
	cuts = [conc[ 
		X(Near(loclon)),
		Y(Near(loclat)),
		Ti(At(datetoplot)),
		Dim{:pointspec}(ind),
		Dim{:nageclass}(1),
	][:, 1] for ind in relvertcut]
	Plots.plot(cuts, heights, marker = :circle,
		title = "Vertical concentration",
		ylabel = "Height [m]",
		xlabel = "Concentration [$(concmeta[:units])]",
		labels = reshape(labels, 1, :)
	)
end

# ╔═╡ 41e313a1-d162-48ae-9f2d-9f04a90b4812
getcomment(fpoutput, reltoplot::Int)

# ╔═╡ 6a1113b0-f8bb-4c16-9ad7-016ea2fd9ee1
md"""
Getting all the starts of the releases:
"""

# ╔═╡ 687e855b-da77-44a6-9f8a-2e81936c15a3
fpoutput[:RELSTART].metadata

# ╔═╡ b98d7e54-08ec-405c-9e09-018839f2ec67
simstart = DateTime(stackmeta[:ibdate]*"T"*stackmeta[:ibtime], "yyyymmddTHHMMSS")

# ╔═╡ 08faa892-6e88-4f59-8339-d17791a929cd
relstartsecs = fpoutput[:RELSTART] |> collect

# ╔═╡ d2c580fd-6d34-437d-b713-da865d6ae820
relstarts = [simstart + Second(relstart +1) for relstart in relstartsecs]

# ╔═╡ b70f0ce1-b878-40e3-998e-9f8539629024
md"""
Getting the released mass for each release:
"""

# ╔═╡ 9d781acd-7eea-440a-b902-cdefef81dce4
relmass = fpoutput[:RELXMASS][:, 1] |> collect

# ╔═╡ f01f84a3-60fd-431a-bbc8-1a191f64f7ab
md"""
When each mass has been released:
"""

# ╔═╡ 8aab9deb-7f6b-44c7-841a-d58fece9f863
[[k, v] for (k, v) in zip(relstarts, relmass)]

# ╔═╡ Cell order:
# ╠═206febfe-ba37-11ec-0f21-ed03f153bcab
# ╟─49b230de-26e3-4e25-9030-c2710a6907cc
# ╟─47407d00-4444-4b28-9588-1ba68393c060
# ╟─9dc033f5-2843-4d01-8b3c-b1cebda97a34
# ╠═88f578e0-e4e8-463c-af62-68bfa670a40c
# ╟─946af5a2-b69d-410f-8ab2-ab4e6296eb39
# ╠═76a9d47d-0bc8-4d19-9016-5ca0a11a483d
# ╟─9bfe58a6-d0a5-4334-9001-88f699b28940
# ╟─75895285-efea-4a5a-8d51-2e97a181ac6d
# ╠═2d7ddb42-bf0c-41d1-bfa9-e93331589722
# ╟─b7cdb553-1b47-416f-9b85-729865c54f3f
# ╠═5b2549d1-a5e2-4303-b8ae-f1ce1d44fe24
# ╟─98499abc-28e4-4c4b-b6d5-82c544b7787a
# ╠═0f127fe0-0b48-4d96-9f55-049c474350a8
# ╟─c11768be-d76f-471b-93e0-a12ec99a72a5
# ╠═c938f980-7f7f-40a5-ab29-686c37dac913
# ╟─52102e12-9b7f-42d9-ab87-2fd2b6dbb6e1
# ╠═cebe0897-e926-4249-bf0d-4993e47d902f
# ╟─9c830b44-22fe-47a3-8e54-93246948581e
# ╟─ce4ee8fe-d9cd-4178-92c0-e00dbd5b25f5
# ╟─c2b0d28a-b32c-442e-9701-6e18c12eb115
# ╠═08bcc54d-0cd5-4c80-b13f-4a36e4bb392e
# ╟─fdd0e08c-377a-48f3-a7e3-3d3bb700da84
# ╠═b0d308c2-aefd-4ab7-a144-be9a52151d4c
# ╟─2a7e337f-1724-4d27-92f8-7f3c333cdf35
# ╟─b8f36b6f-bb56-455f-abc2-e26ff5c484b8
# ╠═7f203bac-93bd-4ce5-ae2b-166f8bf70faf
# ╠═ba866f25-58ed-47ce-b18b-c8866ea66141
# ╟─0e0f21db-39e9-4b43-a4be-465af7633312
# ╟─38a6e3b2-d30d-4742-ba95-e99874d14be3
# ╟─b96902c0-e6bd-4064-bf39-f5c031036866
# ╠═7cbfbdfe-aa2d-4083-8b3e-a72db987854f
# ╟─634a7ede-f4a0-406f-ba0c-601ff77ff6c9
# ╠═68106a40-295b-410f-b980-cc79fcc2ac22
# ╠═64789193-ad38-4013-971a-5d50d8050af8
# ╠═37ac8ebe-4ad3-44fe-88be-92a2a3c6e5ce
# ╠═4a45c0ae-43e2-405e-b5d4-0e67b81830aa
# ╠═32f68603-692e-4115-9fab-09821ffc9bf5
# ╟─0030d778-f912-4453-9aac-1cafe321a540
# ╟─eafec9dd-99dc-4689-99b4-0ac3aee2af51
# ╠═9b693aca-2261-48fe-b105-94b4bf8a7133
# ╟─c4694912-a1e4-47aa-b8f4-e2749e45e4a9
# ╟─e1d47d7c-e9c7-40dd-9b9f-d75df636e5b1
# ╠═ec470e9a-2655-44bc-936c-dbb3399a46ab
# ╟─94465487-d387-4b1d-86be-1b7c53c1dc72
# ╠═e5f548bc-d857-461a-8292-811d0eb42f6d
# ╠═c2fb94a2-e4a3-41ed-b56f-a1456612417b
# ╟─0f30699a-0f51-4ccf-ad57-9448a9c4530a
# ╟─381f848e-5944-47be-a872-57789f997a55
# ╠═ab08360b-6f45-4095-98f1-9e34e17b9d5f
# ╟─6467821f-5151-4f6c-9bbe-0342a2557aea
# ╠═468d54cd-7f8f-4294-b557-c6624dd6ddf2
# ╟─a764002c-fc81-4b8d-92a6-f71c61548494
# ╠═2f80013d-7570-40e3-8cf1-dfda09451c12
# ╟─f0f6ebcf-3b27-4ce6-9341-60d7abdeb5e0
# ╠═cb90ee77-ac74-480c-9511-53f69530bf9f
# ╠═4ad360a0-9438-4a16-8ea3-aece3bc16603
# ╠═1642d9df-68a0-495c-b82d-20209e717e45
# ╟─d18dddc7-a3fa-4e3e-99a6-163162c11fc3
# ╟─a80b764a-794a-4c83-877d-e8de75b0c7c2
# ╟─912986f2-d119-41ec-80f3-54215c3e8e62
# ╠═41e313a1-d162-48ae-9f2d-9f04a90b4812
# ╟─2d15d793-5061-4a24-ab75-8c0a8b00f0eb
# ╠═e0a9d60c-f3a5-4853-9431-a043ce980622
# ╟─6a1113b0-f8bb-4c16-9ad7-016ea2fd9ee1
# ╠═687e855b-da77-44a6-9f8a-2e81936c15a3
# ╠═b98d7e54-08ec-405c-9e09-018839f2ec67
# ╠═08faa892-6e88-4f59-8339-d17791a929cd
# ╠═d2c580fd-6d34-437d-b713-da865d6ae820
# ╟─b70f0ce1-b878-40e3-998e-9f8539629024
# ╠═9d781acd-7eea-440a-b902-cdefef81dce4
# ╟─f01f84a3-60fd-431a-bbc8-1a191f64f7ab
# ╠═8aab9deb-7f6b-44c7-841a-d58fece9f863
