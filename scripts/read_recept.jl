
using Flexpart

function read_receptor(fppath, num_receptor = 1; rectype = "conc")
    fpdir = FlexpartDir(fppath)
    
    stack = RasterStack(OutputFiles(fpdir)[1].path)
    dates = dims(stack, Ti)
    
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
        push!(times, fread(fb, 1, Int32)...)
        rl = fread(fb,2, Int32)
    
        push!(rec_dump, fread(fb, num_receptor, Float32)...)
        rl = fread(fb, 2, Int32)
    end
    close(fb)
    times, rec_dump
end

function fread(f::IO, n::Int, T::Type)
    [Base.read(f, t) for t in fill(T, n)]
end