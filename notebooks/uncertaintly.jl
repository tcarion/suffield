### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 67aab33c-2909-11ed-3e99-55f0e08c9d99
begin
	using Pkg
	Pkg.activate("..")
	using GaussianDispersion
	using DimensionalData
	using Plots
	using Distributions
	using Statistics
end

# ╔═╡ d4d66f48-9112-4c29-98bc-3a8fcb4f6c4b
q_d = truncated(Normal(90, 6), 0, 10000)

# ╔═╡ cddb2a12-93a2-4569-871b-97d2b3c304fa
Q_distrib = rand(q_d, 10000)

# ╔═╡ d6145990-710e-453d-a89d-d041a25f7ea4
Q_mean = mean(Q_distrib)

# ╔═╡ 6655edb2-6770-4629-bc7e-4e8bc94cd364
histogram(Q_distrib)

# ╔═╡ b9b2c7c5-69ab-4754-a9e7-92733ad542b1
plumes_q = [GaussianDispersionParams(;release = ReleaseParams(Q = q)) for q in Q_distrib]

# ╔═╡ 366412ed-d9a6-4097-8a4c-080dd561ef2f
c_1500 = [plume(1500, 0, 2) for plume in plumes_q]

# ╔═╡ 8cad95e2-1828-4200-a2df-b7028f37df55
histogram(c_1500 .* 1e3)

# ╔═╡ 8e002012-98cb-4bec-9c40-ce2bbecced05
c_1500_mean = mean(c_1500)

# ╔═╡ 67441c0b-bf88-47e1-a493-55d9ab47de82
c_1500_var = var(c_1500)

# ╔═╡ dccae1e2-f456-4706-a302-973d54ac4408
c_1500_std = sqrt(c_1500_var)

# ╔═╡ 93ed1c2c-6021-421a-ab4a-5d4aefb41597
plume = GaussianDispersionParams(;release=ReleaseParams(Q = Q_mean))

# ╔═╡ 1397e430-dd19-44a8-a09c-de9c427ef5a7
xs = range(0, 1500, length=100)

# ╔═╡ f8a0d822-a35a-4736-a51f-9b26152b6b24
ys = range(-50, 50, length=100)

# ╔═╡ 112da541-787a-41e0-868b-d203f8e8cd66
zs = range(0, 100, length=100)

# ╔═╡ 6f77a117-00a7-4c33-bf93-80a041a02b0e
array3d = DimArray([plume(xi, yi, zi) for xi in xs, yi in ys, zi in zs], (X(xs), Y(ys), Z(zs))) .* 1e3

# ╔═╡ 4fbbd19f-8e68-4db5-b595-26836af6dadd
plot(xs, plume.(xs, 0, 2))

# ╔═╡ 69770507-10c8-4fa7-a191-f3576c6c968d
plume(1500, 0, 2)

# ╔═╡ Cell order:
# ╠═67aab33c-2909-11ed-3e99-55f0e08c9d99
# ╠═d4d66f48-9112-4c29-98bc-3a8fcb4f6c4b
# ╠═cddb2a12-93a2-4569-871b-97d2b3c304fa
# ╠═d6145990-710e-453d-a89d-d041a25f7ea4
# ╠═6655edb2-6770-4629-bc7e-4e8bc94cd364
# ╠═b9b2c7c5-69ab-4754-a9e7-92733ad542b1
# ╠═366412ed-d9a6-4097-8a4c-080dd561ef2f
# ╠═8cad95e2-1828-4200-a2df-b7028f37df55
# ╠═8e002012-98cb-4bec-9c40-ce2bbecced05
# ╠═67441c0b-bf88-47e1-a493-55d9ab47de82
# ╠═dccae1e2-f456-4706-a302-973d54ac4408
# ╠═93ed1c2c-6021-421a-ab4a-5d4aefb41597
# ╠═1397e430-dd19-44a8-a09c-de9c427ef5a7
# ╠═f8a0d822-a35a-4736-a51f-9b26152b6b24
# ╠═112da541-787a-41e0-868b-d203f8e8cd66
# ╠═6f77a117-00a7-4c33-bf93-80a041a02b0e
# ╠═4fbbd19f-8e68-4db5-b595-26836af6dadd
# ╠═69770507-10c8-4fa7-a191-f3576c6c968d
