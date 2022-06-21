using DataFrames
using CSV
using Dates
using CoolProp
using Chain

function to_datetime(date, time)
    ftime = time isa Time ? time : Time(time, "H:M:S")
    DateTime(date, ftime)
end

release_rate(start, stop, mass) = mass / Dates.value(Dates.Second(stop - start))

function process()
    releases = DataFrame(CSV.File("releases_ds/releases.csv"))
    species = DataFrame(CSV.File("releases_ds/species.csv"))

    valid_releases = dropmissing(releases, [:start, :stop])

    valid_releases = @chain valid_releases begin
        # combine(_, :, [:date, :start] => (d, s) -> DateTime.(d, s))
        # combine(_, :, [:date, :stop] => (d, s) -> DateTime.(d, s))
        # rename(_, :date_start_function => :startdt)
        # rename(_, :date_stop_function => :stopdt)
        transform(_, :, [:date, :start] => ( (f, s) -> (start_utc = DateTime.(f, s),) ) => AsTable )
        transform(_, :, [:date, :stop] => ( (f, s) -> (stop_utc = DateTime.(f, s),) ) => AsTable )
    end
    valid_releases.delta_t = Dates.value.(Second.(valid_releases.stop_utc .- valid_releases.start_utc))
    valid_releases.mass = valid_releases.mass * 1000 # kg -> g
    numb_lines = size(valid_releases, 1)
    valid_releases.density = fill(0., numb_lines)
    valid_releases.isflow = fill(false, numb_lines)
    # valid_releases.delta_t[1] = 3
    for rel in eachrow(valid_releases)
        if ismissing(rel[:mass]) && !ismissing(rel[:pressure])
            rflow = rel[:flow] * 1e-3 / 60 # L/min -> m^3/s
            rdate = rel.date
            vol = rel.delta_t * rflow

            cas = first(species[species.code .==  rel.species, :])[:CAS]
            p = rel[:pressure] * 6894.76 # psi -> Pa
            T = 303 # K
            density = PropsSI("D", "P", p, "T", T, cas)
            rel[:mass] = density * vol * 1000 # [kg]
            rel[:density] = density
            rel[:isflow] = true
        end
    end

    # valid_releases.start_utc = DateTime.(valid_releases.date, valid_releases.start)
    valid_releases.Q = valid_releases.mass ./ valid_releases.delta_t # emission rate [g/s]
    valid_releases
end

df = process()
CSV.write("releases_ds/valid_releases.csv", df)