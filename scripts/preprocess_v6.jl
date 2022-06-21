using DataFrames
using CSV
using XLSX

filename = "releases_ds/Input_parameters_chemicals_V6.xlsx"
xlfile = XLSX.readxlsx(filename)["Model_input_mod2"]
data = xlfile[:]
df = DataFrame( data[2:end, :], :auto)
df = DataFrame(XLSX.readtable(filename, "Model_input_mod2"; first_row = 2))
