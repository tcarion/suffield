
using XLSX
using DataFrames
using Unitful
using Dates

function read_sensor_pm(xlfile = "sensors_ds/Aerosol_SiteA_release.xlsx", sheetname = "1808_J4230 MS"; rho = 1174)
    part_sizes = [0.3, 0.4, 0.5, 0.65, 0.8, 1., 1.6, 2, 3., 4., 5., 7.5, 10, 15, 20]
    fsizes = Symbol.(replace.("s" .* string.(part_sizes), "." => "_"))
    
    colnames = [
        :date, :julia, :time_local, :time_utc, fsizes..., :t, :RH, :u
    ];
    
    df = DataFrame(XLSX.readtable(xlfile, sheetname; first_row = 4, column_labels = colnames)...)

    datef = Date(2014, parse(Int64, sheetname[3:4]), parse(Int64, sheetname[1:2]))
    times = datef .+ Time.(string.(df.time_utc), "HH:MM:SS")
    concentration = map(eachrow(df)) do row
        partsnums = row[fsizes] |> collect
        perbin, logmeans = particles_to_bin(part_sizes, partsnums)
        concs = massconc.(logmeans * 1u"μm", perbin * 1u"1/m^3", rho*u"kg/m^3") .|> u"g/m^3"
        sum(concs)
    end
    (time = times, concentration = concentration)
end

function particles_to_bin(sizes, particles)
	perbin = Vector{Float64}(undef, length(sizes))
	logmeans = Vector{Float64}(undef, length(sizes))
	for i in 1:length(sizes)-1
		logmeans[i] = logmean(sizes[i+1], sizes[i])
		perbin[i] = particles[i] - particles[i+1]
	end
	perbin[end] = particles[end]
	logmeans[end] = sizes[end]
	replace!(x -> x <= 0 ? 0.0001 : x, perbin)
    perbin, logmeans
end

function massconc(size, partnum, rho = 1.174*u"kg/m^3")
	D = size
	V = 4pi * (D/2)^3 / 3
	m = V * rho
	m * partnum
end

logmean(a, b) = 10^((log10(a) + log10(b)) / 2)

getsheets(xlfile = "sensors_ds/Aerosol_SiteA_release.xlsx") = XLSX.sheetnames(XLSX.readxlsx(xlfile))