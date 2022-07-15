using GaussianPlume
using Plots

relpar = ReleaseParams(h = 30, Q = 5, u = 2)

params = GaussianPlumeParams(release = relpar)

params.stabilities = Set([D])

xs = range(0, 2500)

cground = concentration.(xs, 0, 0, Ref(params))
caxes = concentration.(xs, 0, 30, Ref(params))
plot(xs, cground * 1e6, ylim = [0, 500])
plot!(xs, caxes * 1e6)