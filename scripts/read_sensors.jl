using XLSX
using Dates
using DataFrames

function read_sensors(filepath=joinpath("sensors_ds", "Sensors_chemicals_concentration.xlsm"); sheetname="1308_J4225", cols=["L", "N"], firstrow=4, date = Date(2014,08,13))
    sheet = XLSX.readxlsx(filepath)[sheetname]

    # df = DataFrame(XLSX.gettable(sheet, colselect;
    #     first_row=3,
    #     column_labels=["time", "ppm"]
    # )...)

    dftime = DataFrame(XLSX.gettable(sheet, cols[1];
        first_row=firstrow,
        column_labels=["time"]
    )...)
    # Adjust the time to UTC date

    dfppm = DataFrame(XLSX.gettable(sheet, cols[2];
        first_row=firstrow,
        column_labels=["ppm"]
    )...)
    
    DataFrame(
        time = dftime.time .+ date .+ Hour(6),
        ppm = dfppm.ppm,
    )
end