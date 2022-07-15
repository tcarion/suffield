using DataFrames
using Dates
using Plots

filepath = "/home/tcarion/Documents/suffield/Che-Dispersion-CA/BE_team_ SET-190_Trial/Trial/Sensors_data/Data Xams"
fn = "X-am 7000_ARAA0092_13_8_2014.txt"
fn = "X-am 7000_ARYD0215_15_8_2014.txt"
filename = joinpath(filepath, fn)

function isnum(a)
    try 
        parse(Float64, a)
    catch
        return false
    end
    true
end
plot(filter_nh3df.time, filter_nh3df.nh3, xrotation = 15)

function sensor_log(filepath, specie)
    function isnum(a)
        try 
            parse(Float64, a)
        catch
            return false
        end
        true
    end

    dformat = "m/d/yyyy HH:MM:SS p"

    lines = readlines(filepath)

    specie = specie

    gastypes = lines[findfirst(x -> occursin("GASTYPE", x), lines)]
    gastypes_v = split(split(gastypes, ";;")[2], ";")
    igas = findfirst(x -> occursin(specie, lowercase(x)), gastypes_v)

    vals = filter(x -> occursin("VAL",x), lines)

    svals = split.(vals, ";")

    datestring = [sval[2] for sval in svals]
    dates = DateTime.(datestring, dformat)

    nh3 = [sval[igas+2] for sval in svals]

    nh3df = DataFrame(time = dates, nh3 = nh3)

    filter_nh3df = filter(:nh3 => isnum, nh3df)

    filter_nh3df.nh3 = parse.(Float64, filter_nh3df.nh3)
    filter_nh3df
end

files = readdir("sensors_ds/xams/data Xams workfolder", join = true)

for f in files
    try
        sensor = sensor_log(f, "nh3")
        plot(sensor.time, sensor.nh3, xrotation = 10, label =false, ylabel = "conc [ppm]")
        savefig(joinpath("images/sensor_logs/nh3", basename(f)*".png"))
    catch
    end
end