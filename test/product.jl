using Distributions
using FillArrays

using Test
using Random
using LinearAlgebra

using Distributions: Product

# TODO: remove when `Product` is removed
@testset "Deprecated `Product` distribution" begin
@testset "Testing normal product distributions" begin
    Random.seed!(123456)
    N = 11
    # Construct independent distributions and `Product` distribution from these.
    μ = randn(N)
    ds = Normal.(μ, 1.0)
    x = rand.(ds)
    d_product = @test_deprecated(Product(ds))
    @test d_product isa Product
    # Check that methods for `Product` are consistent.
    @test length(d_product) == length(ds)
    @test eltype(d_product) === eltype(ds[1])
    @test logpdf(d_product, x) ≈ sum(logpdf.(ds, x))
    @test mean(d_product) == mean.(ds)
    @test var(d_product) == var.(ds)
    @test cov(d_product) == Diagonal(var.(ds))
    @test entropy(d_product) ≈ sum(entropy.(ds))

    y = rand(d_product)
    @test y isa typeof(x)
    @test length(y) == N
end

@testset "Testing generic product distributions" begin
    Random.seed!(123456)
    N = 11
    # Construct independent distributions and `Product` distribution from these.
    ubound = rand(N)
    ds = Uniform.(-ubound, ubound)
    x = rand.(ds)
    d_product = @test_deprecated(product_distribution(ds))
    @test d_product isa Product
    # Check that methods for `Product` are consistent.
    @test length(d_product) == length(ds)
    @test eltype(d_product) === eltype(ds[1])
    @test logpdf(d_product, x) ≈ sum(logpdf.(ds, x))
    @test mean(d_product) == mean.(ds)
    @test var(d_product) == var.(ds)
    @test cov(d_product) == Diagonal(var.(ds))
    @test entropy(d_product) == sum(entropy.(ds))
    @test insupport(d_product, ubound) == true
    @test insupport(d_product, ubound .+ 1) == false
    @test minimum(d_product) == -ubound
    @test maximum(d_product) == ubound
    @test extrema(d_product) == (-ubound, ubound)
    @test isless(extrema(d_product)...)

    y = rand(d_product)
    @test y isa typeof(x)
    @test length(y) == N
end

@testset "Testing discrete non-parametric product distribution" begin
    Random.seed!(123456)
    N = 11

    for a in ([0, 1], [-0.5, 0.5])
        # Construct independent distributions and `Product` distribution from these.
        support = fill(a, N)
        ds = DiscreteNonParametric.(support, Ref([0.5, 0.5]))
        x = rand.(ds)
        d_product = @test_deprecated(product_distribution(ds))
        @test d_product isa Product
        # Check that methods for `Product` are consistent.
        @test length(d_product) == length(ds)
        @test eltype(d_product) === eltype(ds[1])
        @test logpdf(d_product, x) ≈ sum(logpdf.(ds, x))
        @test mean(d_product) == mean.(ds)
        @test var(d_product) == var.(ds)
        @test cov(d_product) == Diagonal(var.(ds))
        @test entropy(d_product) == sum(entropy.(ds))
        @test insupport(d_product, fill(a[2], N)) == true
        @test insupport(d_product, fill(a[2] + 1, N)) == false

        y = rand(d_product)
        @test y isa typeof(x)
        @test length(y) == N
    end
end

@testset "Testing iid product distributions" begin
    Random.seed!(123456)
    N = 11
    d = Product(Fill(Laplace(0.0, 2.3), N))
    @test N == length(unique(rand(d)));
    @test mean(d) === Fill(0.0, N)
    @test cov(d) === Diagonal(Fill(var(Laplace(0.0, 2.3)), N))
end
end

@testset "Testing normal product distributions" begin
    Random.seed!(123456)
    N = 11

    # Construct independent distributions and `ProductDistribution` from these.
    μ = randn(N)

    ds1 = Normal.(μ, 1.0)
    d_product1 = @inferred(product_distribution(ds1))
    @test d_product1 isa Distributions.DiagNormal

    ds2 = Fill(Normal(first(μ), 1.0), N)
    d_product2 = @inferred(product_distribution(ds2))
    @test d_product2 isa MvNormal{Float64,Distributions.ScalMat{Float64},<:Fill{Float64,1}}

    # Check that methods for `ProductDistribution` are consistent.
    for (ds, d_product) in ((ds1, d_product1), (ds2, d_product2))
        @test length(d_product) == length(ds)
        @test eltype(d_product) === eltype(ds[1])
        @test mean(d_product) == mean.(ds)
        @test var(d_product) == var.(ds)
        @test cov(d_product) == Diagonal(var.(ds))
        @test entropy(d_product) ≈ sum(entropy.(ds))

        x = rand(d_product)
        @test x isa typeof(rand.(collect(ds)))
        @test length(x) == N
        @test logpdf(d_product, x) ≈ sum(logpdf.(ds, x))
    end
end

@testset "Testing generic VectorOfUnivariateDistribution" begin
    Random.seed!(123456)
    N = 11

    # Construct independent distributions and `ProductDistribution` from these.
    ubound = rand(N)

    ds1 = Uniform.(0.0, ubound)
    # Replace with
    # d_product1 = @inferred(product_distribution(ds1))
    # when `Product` is removed
    d_product1 = @inferred(Distributions.ProductDistribution(ds1))
    @test d_product1 isa Distributions.VectorOfUnivariateDistribution{<:Vector,Continuous,Float64}

    d_product2 = @inferred(product_distribution(ntuple(i -> Uniform(0.0, ubound[i]), 11)...))
    @test d_product2 isa Distributions.VectorOfUnivariateDistribution{<:Tuple,Continuous,Float64}

    ds3 = Fill(Uniform(0.0, first(ubound)), N)
    # Replace with
    # d_product3 = @inferred(product_distribution(ds3))
    # when `Product` is removed
    d_product3 = @inferred(Distributions.ProductDistribution(ds3))
    @test d_product3 isa Distributions.VectorOfUnivariateDistribution{<:Fill,Continuous,Float64}

    # Check that methods for `VectorOfUnivariateDistribution` are consistent.
    for (ds, d_product) in ((ds1, d_product1), (ds1, d_product2), (ds3, d_product3))
        @test length(d_product) == length(ds)
        @test eltype(d_product) === eltype(ds[1])
        @test @inferred(mean(d_product)) == mean.(ds)
        @test @inferred(var(d_product)) == var.(ds)
        @test @inferred(cov(d_product)) == Diagonal(var.(ds))
        @test @inferred(entropy(d_product)) == sum(entropy.(ds))
        @test insupport(d_product, zeros(N))
        @test insupport(d_product, maximum.(ds))
        @test !insupport(d_product, maximum.(ds) .+ 1)
        @test !insupport(d_product, zeros(N + 1))

        @test minimum(d_product) == map(minimum, ds)
        @test maximum(d_product) == map(maximum, ds)
        @test extrema(d_product) == (map(minimum, ds), map(maximum, ds))

        x = @inferred(rand(d_product))
        @test x isa typeof(rand.(collect(ds)))
        @test length(x) == length(d_product)
        @test insupport(d_product, x)
        @test @inferred(logpdf(d_product, x)) ≈ sum(logpdf.(ds, x))
        # ensure that samples are different, in particular if `Fill` is used
        @test length(unique(x)) == N
    end
end

@testset "Testing discrete non-parametric VectorOfUnivariateDistribution" begin
    Random.seed!(123456)
    N = 11

    for a in ([0, 1], [-0.5, 0.5])
        # Construct independent distributions and `ProductDistribution` from these.
        ds1 = DiscreteNonParametric.(fill(a, N), Ref([0.5, 0.5]))
        # Replace with
        # d_product1 = @inferred(product_distribution(ds1))
        # when `Product` is removed
        d_product1 = @inferred(Distributions.ProductDistribution(ds1))
        @test d_product1 isa Distributions.VectorOfUnivariateDistribution{<:Vector{<:DiscreteNonParametric},Discrete,eltype(a)}

        d_product2 = @inferred(product_distribution(ntuple(_ -> DiscreteNonParametric(a, [0.5, 0.5]), 11)...))
        @test d_product2 isa Distributions.VectorOfUnivariateDistribution{<:NTuple{N,<:DiscreteNonParametric},Discrete,eltype(a)}

        ds3 = Fill(DiscreteNonParametric(a, [0.5, 0.5]), N)
        # Replace with
        # d_product3 = @inferred(product_distribution(ds3))
        # when `Product` is removed
        d_product3 = @inferred(Distributions.ProductDistribution(ds3))
        @test d_product3 isa Distributions.VectorOfUnivariateDistribution{<:Fill{<:DiscreteNonParametric,1},Discrete,eltype(a)}

        # Check that methods for `VectorOfUnivariateDistribution` are consistent.
        for (ds, d_product) in ((ds1, d_product1), (ds1, d_product3), (ds3, d_product2))
            @test length(d_product) == length(ds)
            @test eltype(d_product) === eltype(ds[1])
            @test @inferred(mean(d_product)) == mean.(ds)
            @test @inferred(var(d_product)) == var.(ds)
            @test @inferred(cov(d_product)) == Diagonal(var.(ds))
            @test @inferred(entropy(d_product)) == sum(entropy.(ds))
            @test insupport(d_product, fill(a[2], N))
            @test !insupport(d_product, fill(a[2] + 1, N))
            @test !insupport(d_product, fill(a[2], N + 1))

            @test minimum(d_product) == map(minimum, ds)
            @test maximum(d_product) == map(maximum, ds)
            @test extrema(d_product) == (map(minimum, ds), map(maximum, ds))

            x = @inferred(rand(d_product))
            @test x isa typeof(rand.(collect(ds)))
            @test length(x) == length(d_product)
            @test insupport(d_product, x)
            @test @inferred(logpdf(d_product, x)) ≈ sum(logpdf.(ds, x))
            # ensure that samples are different, in particular if `Fill` is used
            @test length(unique(x)) == 2
        end
    end
end

@testset "Testing tuple of continuous and discrete distribution" begin
    Random.seed!(123456)
    N = 11

    ds = (Bernoulli(0.3), Uniform(0.0, 0.7), Categorical([0.4, 0.2, 0.4]))
    d_product = @inferred(product_distribution(ds...))
    @test d_product isa Distributions.VectorOfUnivariateDistribution{<:Tuple,Continuous,Float64}

    ds_vec = vcat(ds...)

    @test length(d_product) == 3
    @test eltype(d_product) === Float64
    @test @inferred(mean(d_product)) == mean.(ds_vec)
    @test @inferred(var(d_product)) == var.(ds_vec)
    @test @inferred(cov(d_product)) == Diagonal(var.(ds_vec))
    @test @inferred(entropy(d_product)) == sum(entropy.(ds_vec))
    @test insupport(d_product, [0, 0.2, 3])
    @test !insupport(d_product, [-0.5, 0.2, 3])
    @test !insupport(d_product, [0, -0.5, 3])
    @test !insupport(d_product, [0, 0.2, -0.5])

    @test @inferred(minimum(d_product)) == map(minimum, ds_vec)
    @test @inferred(maximum(d_product)) == map(maximum, ds_vec)
    @test @inferred(extrema(d_product)) == (map(minimum, ds_vec), map(maximum, ds_vec))

    x = @inferred(rand(d_product))
    @test x isa Vector{Float64}
    @test length(x) == length(d_product)
    @test insupport(d_product, x)
    @test @inferred(logpdf(d_product, x)) ≈ sum(logpdf.(ds, x))
end

@testset "Testing generic MatrixOfUnivariateDistribution" begin
    Random.seed!(123456)
    M, N = 11, 16

    # Construct independent distributions and `ProductDistribution` from these.
    ubound = rand(M, N)

    ds1 = Uniform.(0.0, ubound)
    d_product1 = @inferred(product_distribution(ds1))
    @test d_product1 isa Distributions.MatrixOfUnivariateDistribution{<:Matrix{<:Uniform},Continuous,Float64}

    ds2 = Fill(Uniform(0.0, first(ubound)), M, N)
    d_product2 = @inferred(product_distribution(ds2))
    @test d_product2 isa Distributions.MatrixOfUnivariateDistribution{<:Fill{<:Uniform,2},Continuous,Float64}

    # Check that methods for `MatrixOfUnivariateDistribution` are consistent.
    for (ds, d_product) in ((ds1, d_product1), (ds2, d_product2))
        @test size(d_product) == size(ds)
        @test eltype(d_product) === eltype(ds[1])
        @test @inferred(mean(d_product)) == mean.(ds)
        @test @inferred(var(d_product)) == var.(ds)
        @test @inferred(cov(d_product)) == Diagonal(vec(var.(ds)))
        @test @inferred(cov(d_product, Val(false))) == reshape(Diagonal(vec(var.(ds))), M, N, M, N)

        @test minimum(d_product) == map(minimum, ds)
        @test maximum(d_product) == map(maximum, ds)
        @test extrema(d_product) == (map(minimum, ds), map(maximum, ds))

        x = @inferred(rand(d_product))
        @test size(x) == size(d_product)
        @test x isa typeof(rand.(collect(ds)))
        @test @inferred(logpdf(d_product, x)) ≈ sum(logpdf.(ds, x))
        # ensure that samples are different, in particular if `Fill` is used
        @test length(unique(x)) == length(d_product)
    end
end

@testset "Testing generic array of multivariate distribution" begin
    Random.seed!(123456)
    M = 3

    for N in ((11,), (11, 3))
        # Construct independent distributions and `ProductDistribution` from these.
        alphas = [normalize!(rand(M), 1) for _ in Iterators.product(map(x -> 1:x, N)...)]

        ds1 = Dirichlet.(alphas)
        d_product1 = @inferred(product_distribution(ds1))
        @test d_product1 isa Distributions.ProductDistribution{length(N) + 1,1,<:Array{<:Dirichlet{Float64},length(N)},Continuous,Float64}

        ds2 = Fill(Dirichlet(first(alphas)), N...)
        d_product2 = @inferred(product_distribution(ds2))
        @test d_product2 isa Distributions.ProductDistribution{length(N) + 1,1,<:Fill{<:Dirichlet{Float64},length(N)},Continuous,Float64}

        # Check that methods for `VectorOfMultivariateDistribution` are consistent.
        for (ds, d_product) in ((ds1, d_product1), (ds2, d_product2))
            @test size(d_product) == (length(ds[1]), size(ds)...)
            @test eltype(d_product) === eltype(ds[1])
            @test @inferred(mean(d_product)) == reshape(mapreduce(mean, (x, y) -> cat(x, y; dims=ndims(ds) + 1), ds), size(d_product))
            @test @inferred(var(d_product)) == reshape(mapreduce(var, (x, y) -> cat(x, y; dims=ndims(ds) + 1), ds), size(d_product))
            @test @inferred(cov(d_product)) == Diagonal(mapreduce(var, vcat, ds))

            if d_product isa MatrixDistribution
                @test @inferred(cov(d_product, Val(false))) == reshape(
                    Diagonal(mapreduce(var, vcat, ds)), M, length(ds), M, length(ds)
                )
            end

            x = @inferred(rand(d_product))
            @test size(x) == size(d_product)
            @test x isa typeof(mapreduce(rand, (x, y) -> cat(x, y; dims=ndims(ds) + 1), ds))

            # inference broken for non-Fill arrays
            y = reshape(x, Val(2))
            if ds isa Fill
                @test @inferred(logpdf(d_product, x)) ≈ sum(logpdf(d, y[:, i]) for (i, d) in enumerate(ds))
            else
                @test logpdf(d_product, x) ≈ sum(logpdf(d, y[:, i]) for (i, d) in enumerate(ds))
            end
            # ensure that samples are different, in particular if `Fill` is used
            @test length(unique(x)) == length(d_product)
        end
    end
end