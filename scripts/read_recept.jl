
using Flexpart
using Rasters
using DataFrames
using Dates

function fread(f::IO, n::Int, T::Type)
    [Base.read(f, t) for t in fill(T, n)]
end

"""
    read_receptor(fpdir::FlexpartDir, num_receptor = 1; rectype = "conc")
If `rectype` == "conc", units are ng/m³
If `rectype` == "pptv", units are pptv

"""
function read_receptor(fpdir::FlexpartDir, num_receptor = 1; rectype = "conc")

    
    stack = RasterStack(OutputFiles(fpdir)[1].path)
    dates = dims(stack, Ti)
    t0 = dates[1] - Second(metadata(stack)[:loutstep])
    receptor_path = joinpath(fpdir[:output], "receptor_"*rectype)
    num_receptor = 1
    
    fb = open(receptor_path, "r")

    rl = fread(fb, 1, Int32)

    rname = fread(fb, 16, Char)
    receptorname = String(rname)


    rl2 = fread(fb, 2, Int32)

    receptorloc = fread(fb,2, Float32)

    rl2 = fread(fb, 2, Int32)

    rec_dump = Float32[]
    times = Int32[]
    for _ in 1:length(dates)-1
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
    times = t0 .+ Second.(times)
    df = DataFrame(time=times)
    df[!, Symbol(rectype)] = rec_dump
    df
end

read_receptor(fppath::String, num_receptor = 1; rectype = "conc") = read_receptor(FlexpartDir(fppath), num_receptor; rectype)