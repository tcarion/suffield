using XLSX
using Dates
using DataFrames

filename = joinpath("sensors_ds", "Sensors_chemicals_concentration.xlsm")
timecol = "D"

sheet = XLSX.readxlsx(filename)["1808_J4230"]

date = sheet["I4"]

table = XLSX.gettable(sheet, "D:E"; 
    first_row = 3, 
    column_labels = ["time", "ppm"]
    )

df = DataFrame(table)

df.time = date .+ df.time .+ Hour(6)

plot(df.time, df.ppm)

seconds, recppv = read_receptor("")
rectime = DateTime(2014,8,18,19) .+ Second.(seconds)

recept = DataFrame(time = rectime, ppv = recppv)

plot(recept.time, recept.ppv)

stack = RasterStack("outputs\\NH3_190821\\output\\grid_conc_20140818190000.nc")
raster = Raster("outputs\\NH3_190821\\output\\grid_conc_20140818190000.nc", name = :spec001_mr)
DateTime(2014, 8, 18, 19) .+ Second.(collect(stack[:RELSTART]) )
stack[:RELPART] |> collect
plot(
    view(raster,
        Dim{:height}(At(2.)),
        Dim{:pointspec}(1),
        Dim{:nageclass}(1),
        Ti(Near(DateTime(2014,8,19, 3, 15))),
    )
    )