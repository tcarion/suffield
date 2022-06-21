using DataFrames
using CSV
using Gadfly
using Cairo
using Dates

releases_path_michal = "releases_ds/gases_releases.csv"
releases_path_tristan = "releases_ds/valid_releases.csv"
releases_michal = DataFrame(CSV.File(releases_path_michal))
releases_tristan = DataFrame(CSV.File(releases_path_tristan))

plot_and_save(releases_tristan, :start_utc, :mass, :species; name = "released_mass_tristan", yunits = "[g]")
plot_and_save(releases_tristan, :start_utc, :Q, :species; name = "emission_rate_tristan", yunits = "[g/s]")
plot_and_save(releases_michal, :start_utc, :mass, :chemical_shortname; name = "released_mass_michal", yunits = "[g]")
plot_and_save(releases_michal, :start_utc, :Q, :chemical_shortname; name = "emission_rate_michal", yunits = "[g/s]")

function plot_and_save(df, x, y, color; spec = "", name = "", yunits = "")
    outputpath = "images/mass_releases"
    dstoplot = spec == "" ? df : subset(df, color => x -> x.==spec)
    dropmissing!(dstoplot, [y])
    pall = plotmass(dstoplot, x, y, color, name, yunits)
    fname =  name * (spec == "" ? "" : "_$spec") * ".png"
    img = PNG(joinpath(outputpath,fname), 25cm, 20cm)
    draw(img, pall)
end

function plotmass(rel, x, y, color, title, yunits)
    xticks = DateTime(2014, 08, 11):Dates.Hour(12):DateTime(2014,08,21)
    # xticks = [DateTime(2014, 08, 11), DateTime(2014,08,20)]
    Gadfly.plot(rel, 
        x=x, y=y,
        color=color, Geom.point, 
        Scale.x_continuous(labels=x -> Dates.format(x, "yyyy-mm-ddTHH:MM")),
        Guide.xticks(ticks=xticks, orientation=:vertical, label=true),
        # Guide.yticks(ticks=0.:0.5:5.5, label=true),
        # Guide.xlabel("Start date"),
        Guide.ylabel("Mass $yunits"),
        # Guide.title("Time series of the released mass for each specie"),
        Guide.title(title),
        Guide.colorkey(title = "Species"),
        Theme(background_color="white"),
        )
end