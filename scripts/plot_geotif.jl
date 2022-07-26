using Rasters
using ColorTypes

struct GeoTiff
    raster::AbstractRaster
end
GeoTiff(path::AbstractString) = GeoTiff(_to_rgb(path))
Base.parent(geotiff::GeoTiff) = geotiff.raster

function _to_rgb(fn)
    rast = Raster(fn)
    rast = reverse(rast, dims = 2)
    red = view(rast, Rasters.Band(1)) |> read
    green = view(rast, Rasters.Band(2)) |> read
    blue = view(rast, Rasters.Band(3)) |> read

    replace!.(x -> isnan(x) ? 0.0 : x, [red, green, blue])

    rgb = fill(RGB(0,0,0), dims(rast, :X), dims(rast, :Y));

    for i in eachindex(red)
        rgb[i] = RGB(red[i] ./ 255, green[i] ./ 255, blue[i] ./ 255)
    end
    eltype(rast) == UInt8 ? rgb./255 : rgb
end

tiffile = "2021-06-29-00 00_2021-06-29-23 59_Landsat_8_L2_True_color_low_8bit.tiff"
satfile = joinpath("images", "sat", tiffile)

tiff = GeoTiff(satfile)

tiffrast = parent(tiff)