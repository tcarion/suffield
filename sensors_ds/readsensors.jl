using DelimitedFiles

filename = "sensors/xam.csv"
data = readdlm(filename, ';')

vals = allvals(data)

function findline(data, value)
    firstcol = data[:, 1]
    ind = findfirst(x -> occursin(value, x), firstcol)
    data[ind, :]
end

function allvals(data)
    inds = findall(x -> occursin("VAL", x), data[:, 1])
    data[inds, :]
end