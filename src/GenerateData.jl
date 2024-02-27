module GenerateData

using QuasiMonteCarlo, Random, LinearAlgebra

# %%

function main()
    N = 2_000_000
    d = 11
    min_max_vals = [
        0.0 10.0;  # A
        0.0 50.0;  # B
        0.0 50.0;  # G
        0.0 2000.0;  # P
        25.0 140.0;  # a
        6.5 110.0;  # b
        350.0 650.0;  # g
        0.0 1350.0;  # c
        2.0 9.0;  # v_0
        0.5 7.5;  # e_0
        0.3 0.8  # r
    ]

    @info "Generating parameter space"
    pars = generate_hypercube(N, d, transpose(min_max_vals))

    # TODO Solve each equation and save results to file
    # TODO Skip if all results have been generated
end

# %%

"""
    generate_hypercube(N::Int, d::Int, min_max_vals::AbstractArray{Float64,2})::Matrix{Float64}

Generate a random Latin Hypercube with `N` points embedded in `d` dimensions within the ranges
specified by the `(2 x d)` matrix `min_max_vals`.
"""
function generate_hypercube(N::Int, d::Int, min_max_vals::AbstractArray{Float64,2})::Matrix{Float64}
    @assert size(min_max_vals) == (2, d)

    min_vals = min_max_vals[1, :]
    range = min_max_vals[2, :] - min_vals
    @assert all(range .> 0)
    scale = diagm(range)

    sampler = QuasiMonteCarlo.LatinHypercubeSample()
    res = QuasiMonteCarlo.sample(N, d, sampler)

    return min_vals .+ scale * res
end

"""
    generate_hypercube(N::Int, d::Int)::Matrix{Float64}

Generate a random Latin Hypercube with `N` points embedded in `d` dimensions within the ranges
`[0, 1]` for each dimension.
"""
function generate_hypercube(N::Int, d::Int)::Matrix{Float64}
    min_max_vals = zeros((2, d))
    min_max_vals[2, :] .= 1
    return generate_hypercube(N, d, min_max_vals)
end

# %%

end # module GenerateData
