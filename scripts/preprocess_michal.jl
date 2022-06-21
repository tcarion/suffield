using DataFrames
using CSV
using Dates
using Chain


input_releases_path = "releases_ds/input_gases_releases.csv"

input_releases = DataFrame(CSV.File(input_releases_path))


input_releases.id = 1:size(input_releases, 1)
newds = @chain input_releases begin
    transform(_, :, [:date, :time_local] => ( (d, t) -> (start_local = _format.(d, t),) ) => AsTable )
    # transform(_, :, [:date, :time_local] => (d, t) -> _format(d, t) => :start_local )
    transform(_, :, [:Q, :delta_t] => ( (q, dt) -> (mass = calcmass.(q, dt),) ) => AsTable )
    transform(_, :start_local => ( x -> (start_utc = x .+ Dates.Hour(6), ) ) => AsTable)
    transform(_, [:start_local, :delta_t] => ( (a, b) -> (end_local = a .+ Dates.Second.(b), ) ) => AsTable)
    transform(_, :end_local => ( x -> (end_utc = x .+ Dates.Hour(6), ) ) => AsTable)

    # combine(_, :, [:Q,] => ( (q, dt) -> (mass = calcmass.(q, dt),) ) => AsTable )
    permuteafter(_, :start_local, :date)
    permuteafter(_, :start_utc, :start_local)
    permuteafter(_, :end_local, :start_local)
    permuteafter(_, :end_utc, :start_utc)
    permuteafter(_, :id, :date)
    permuteafter(_, :date, :id)
    permuteafter(_, :mass, :Q)
end

CSV.write("releases_ds/gases_releases.csv", newds)

calcmass(Q, delta_t) = Q * delta_t

function _format(date, time)
    dateformat = "mm/dd/yyyTHH:MM:SS p"
    DateTime(date*"T"*time, dateformat)
end

function permuteafter(ds::AbstractDataFrame, toperm, pivot)
    cols = Symbol.(names(ds))
    newcols = permuteafter(cols, toperm, pivot)
    ds[:, newcols]
end

function permuteafter(cols::AbstractVector, toperm, pivot)
    io = findfirst(x -> x == pivot, cols)
    ic = findfirst(x -> x == toperm, cols)
    newcols = copy(cols)
    insert!(newcols, io+1, cols[ic])
    io < ic ? deleteat!(newcols, ic+1) : deleteat!(newcols, ic)
    newcols
end
# function _format(date, time)
#     DateTime(_formatdate(date), _formattime(time))
# end

# function _formatdate(date)
#     dateformat = r"(?<month>\d{1,2})\/(?<day>\d{1,2})\/(?<year>\d{1,4})"
#     m = match(dateformat, date)
#     parsed = parse.(Int, [m[:year], m[:month], m[:day]])
#     Date(parsed...)
# end
# function _formattime(time)
#     timeformat = r"(?<hour>\d{1,2}):(?<minute>\d{1,2}):(?<second>\d{1,2})"
#     m = match(timeformat, time)
#     parsed = parse.(Int, [m[:hour], m[:minute], m[:second]])
#     Time(parsed...)
# end

# _format(dates::AbstractVector, times::AbstractVector) = [_format(date, time) for (date, time) in zip(dates, times)]