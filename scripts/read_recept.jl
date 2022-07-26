
using Flexpart
using Rasters
using DataFrames
using Dates

const LocationType = @NamedTuple{lon::Float32, lat::Float32}
struct Receptor
    name::String
    location::LocationType
    time::AbstractVector{<:DateTime}
    concentration::AbstractVector{<:Real}
end

function fread(f::IO, n::Int, T::Type)
    [Base.read(f, t) for t in fill(T, n)]
end

"""
    read_receptor(fpdir::FlexpartDir, num_receptor = 1; rectype = "conc")
If `rectype` == "conc", units are ng/m³
If `rectype` == "pptv", units are pptv

See https://www.flexpart.eu/attachment/wiki/FpOutput/flex_read_recepconc.m
"""
function read_receptor(fpdir::FlexpartDir, num_receptor = 1; rectype = "conc")
    stack = RasterStack(OutputFiles(fpdir)[1].path)
    dates = dims(stack, Ti)
    t0 = dates[1] - Second(metadata(stack)[:loutstep])
    receptor_path = joinpath(fpdir[:output], "receptor_"*rectype)
    
    fb = open(receptor_path, "r")

    rl = fread(fb, 1, Int32)

    receptornames = String[]

    for _ in 1:num_receptor
        rname = fread(fb, 16, Char)
        receptorname = String(rname)
        push!(receptornames, receptorname)
    end


    rl2 = fread(fb, 2, Int32)

    locst = @NamedTuple{lon::Float32, lat::Float32}
    receptorlocs = locst[]
    for _ in 1:num_receptor
        receptorloc = fread(fb,2, Float32)
        push!(receptorlocs, locst(Tuple(receptorloc)))
    end

    rl2 = fread(fb, 2, Int32)

    rec_dump = Float32[]
    times = Int32[]
    ntime = length(dates)-1
    for _ in 1:ntime
        try
            push!(times, fread(fb, 1, Int32)...)
            rl = fread(fb,2, Int32)
        
            push!(rec_dump, fread(fb, num_receptor, Float32)...)
            rl = fread(fb, 2, Int32)
        catch e
            if e isa EOFError
                break
            end
        end

    end
    close(fb)

    concs = reshape(rec_dump, (num_receptor, ntime))
    times = t0 .+ Second.(times)
    
    receptors = Receptor[]
    for i in 1:num_receptor
        receptor = Receptor(receptornames[i], receptorlocs[i], times, concs[i, :])
        push!(receptors, receptor)
    end
    receptors
end

read_receptor(fppath::String, num_receptor = 1; rectype = "conc") = read_receptor(FlexpartDir(fppath), num_receptor; rectype)