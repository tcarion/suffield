using DataFrames
using CSV
using Gadfly
using Compose
using Cairo
using Fontconfig
using Dates
using Plots

releases_path = "releases_ds/releases_from_v6.csv"

df = DataFrame(CSV.File(releases_path))
speciestoplot = filter(x -> !(x in ["R-152a", "C3H8"]), unique(df.chemical_shortname))
daytoplot = Day(18)

begin
    # df = subset(df, :start_utc => ByRow(x -> Day(x) == daytoplot))
    df = subset(df, :chemical_shortname => ByRow(x -> x in speciestoplot))
end

Gadfly.plot(df,
    # x=x, 
    y=:Q,
    xmin=:start_utc,
    xmax=:end_utc,
    color=:chemical_shortname, Geom.errorbar,
    # Scale.x_continuous(labels=x -> Dates.format(x, "yyyy-mm-ddTHH:MM")),
    # Guide.xticks(ticks=xticks, orientation=:vertical, label=true),
    # # Guide.yticks(ticks=0.:0.5:5.5, label=true),
    # # Guide.xlabel("Start date"),
    # Guide.ylabel("Mass $yunits"),
    # # Guide.title("Time series of the released mass for each specie"),
    # Guide.title(title),
    # Guide.colorkey(title = "Species"),
    Theme(background_color="white"),
)

begin
    theme = Theme(
        background_color="white",
        boxplot_spacing=0.3cx,
        minor_label_font_size=18pt,
        major_label_font_size=22pt,
        # key_title_font_size=18pt
    )

    Gadfly.push_theme(theme)
end
set_default_plot_size(14cm, 10cm)

begin
    deltat = Gadfly.plot(df,
        x=:chemical_shortname,
        y=:delta_t,
        # color=:chemical_shortname, 
        Geom.boxplot,
        # Guide.title("Time interval"),
        Guide.ylabel("duration [s]"),
        Guide.xlabel(""),
        Coord.cartesian(ymin=0, ymax=400)
    )
    outputpath = "images/mass_releases"
    img = PNG(joinpath(outputpath, "boxplot_deltat.png"), 20cm, 15cm)
    draw(img, deltat)
end

begin
    qplot = Gadfly.plot(df,
        x=:chemical_shortname,
        y=:Q,
        # color=:chemical_shortname, 
        Geom.boxplot,
        # Guide.title("Releases emission rate"),
        Guide.ylabel("emission rate [g/s]"),
        Guide.xlabel(""),
    )
    img = PNG(joinpath(outputpath, "boxplot_Q.png"), 20cm, 15cm)
    draw(img, qplot)
end

begin
    p = plot(xlabel="Time", ylabel="Release rate [g/s]")

    for row in eachrow(df)
        plot!(p, [(row.start_utc, row.Q), (row.end_utc, row.Q)], label=row.chemical_shortname)
    end
    p
end


releases_path_michal = "releases_ds/gases_releases.csv"
releases_path_tristan = "releases_ds/valid_releases.csv"
releases_michal = DataFrame(CSV.File(releases_path_michal))
releases_tristan = DataFrame(CSV.File(releases_path_tristan))

plot_and_save(releases_tristan, :start_utc, :mass, :species; name="released_mass_tristan", yunits="[g]")
plot_and_save(releases_tristan, :start_utc, :Q, :species; name="emission_rate_tristan", yunits="[g/s]")
plot_and_save(releases_michal, :start_utc, :mass, :chemical_shortname; name="released_mass_michal", yunits="[g]")
plot_and_save(releases_michal, :start_utc, :Q, :chemical_shortname; name="emission_rate_michal", yunits="[g/s]")

function plot_and_save(df, x, y, color; spec="", name="", yunits="")
    outputpath = "images/mass_releases"
    dstoplot = spec == "" ? df : subset(df, color => x -> x .== spec)
    dropmissing!(dstoplot, [y])
    pall = plotmass(dstoplot, x, y, color, name, yunits)
    fname = name * (spec == "" ? "" : "_$spec") * ".png"
    img = PNG(joinpath(outputpath, fname), 25cm, 20cm)
    draw(img, pall)
end

function plotmass(rel, x, y, color, title, yunits)
    xticks = DateTime(2014, 08, 11):Dates.Hour(12):DateTime(2014, 08, 21)
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
        Guide.colorkey(title="Species"),
        Theme(background_color="white"),
    )
end