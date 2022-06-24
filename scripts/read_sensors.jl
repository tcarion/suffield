using XLSX
using Dates
using DataFrames

function read_sensors(filepath=joinpath("sensors_ds", "Sensors_chemicals_concentration.xlsm"); sheetname="1808_J4230", colselect="D:E")
    sheet = XLSX.readxlsx(filepath)[sheetname]

    date = sheet["I4"]

    df = DataFrame(XLSX.gettable(sheet, colselect;
        first_row=3,
        column_labels=["time", "ppm"]
    )...)

    # Adjust the time to UTC date
    df.time = date .+ df.time .+ Hour(6)

    df
end
