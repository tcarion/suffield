using Plots

include("read_sensor_pm.jl")

xlfile = "sensors_ds/Aerosol_SiteA_release.xlsx"
sheets = getsheets()[2:end]

for sheetname in sheets
    println(sheetname)
    try
        time, conc = read_sensor_pm(xlfile, sheetname)
        plot(time, conc .|> u"mg/m^3" .|> ustrip, ylabel = "mg / m³", label=false)
        savefig(joinpath("images", "sensor_logs", "aerosols", sheetname*".png"))
    catch e
        println(sheetname*" not written because of")
        show(e)
    end
end

