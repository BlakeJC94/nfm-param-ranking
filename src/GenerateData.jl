module GenerateData

# %%
using QuasiMonteCarlo, Random, LinearAlgebra, DifferentialEquations

function main()
    N = 5 # 2_000_000
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
    T = 20  # Max simulation time
    T0 = 10  # Transient end time (discard signal up to this t value)
    Fs = 500  # Sampling frequency

    @info "Generating parameter space"
    param_configs = generate_hypercube(N, d, transpose(min_max_vals))

    # TODO Solve each equation and save results to file
    @info "Solving model for each configuration"
    results = []
    for i = 1:N
        @info "sim $(i)"
        if i % 100 == 0
            @info "sim $(i)"
        end

        dt = 1/Fs  # Sampling period
        y0 = zeros(10, 1)  # Initial conditions
        param_config = param_configs[:, i]

        prob = ODEProblem(jansen_ritt_wendling!, y0, (0, T), param_config)
        sol = solve(prob, DP5(), dt=dt, adaptive=false)

        Y = sol[2,:][T0*Fs:end] - sol[3,:][T0*Fs:end] - sol[4,:][T0*Fs:end]
        push!(results, Y)
        # TODO Save?
    end
    return results

    # TODO Skip if all results have been generated
    #
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

"""
    sig(v, v0, e0, r)

A sigmoid function that relates the average postsynaptic potential of a given population to an
average pulse density of action potentials outgoing from the population.
"""
sig(v, v0, e0, r) = 2 * e0 / (1 + exp(r * (v0 - v)))


# TODO Finish docs
"""
    jansen_ritt_wendling!(dy, y, p, t)

The extension of the Jansen-Rit model introduced by Wendling et al.

Classically has been used to study transitions to seizure dynamics. It has previously been shown to
display a repertoire of important dynamics which occur at ictal and interictal states. The model is
based on the assumption of the existence of four populations of neurons: pyramidal cells; excitatory
interneurons; slow and fast inhibitory interneurons. The activity of each population is governed by
the interactions between them.

Written for use with `DifferentialEquations.jl`
"""
function jansen_ritt_wendling!(dy, y, p, t)
    y1, y2, y3, y4, y5, y6, y7, y8, y9, y10 = y

    A, B, G = p[1:3]
    P = p[4]
    a, b, g = p[5:7]
    C = p[8]
    v0, e0, r = p[9:11]

    C1 = C
    C2 = 0.8 * C
    C3 = 0.25 * C
    C4 = 0.25 * C
    C5 = 0.3 * C
    C6 = 0.1 * C
    C7 = 0.8 * C

    S6 = sig(y2 - y3 - y4, v0, e0, r)
    dy[1] = y6
    dy[6] = A * a * S6 - 2 * a * y6 - a^2 * y1

    S7 = sig(C1 * y1, v0, e0, r)
    dy[2] = y7
    dy[7] = A * a * (P + C2 * S7) - 2 * a * y7 - a * a * y2

    S8 = sig(C3 * y1, v0, e0, r)
    dy[3] = y8
    dy[8] = B * b * C4 * S8 - 2 * b * y8 - b^2 * y3

    S9 = sig(C5 * y1 - y5, v0, e0, r)
    dy[4] = y9
    dy[9] = G * g * C7 * S9 - 2 * g * y9 - g^2 * y4

    S10 = sig(C3 * y1, v0, e0, r)
    dy[5] = y10
    dy[10] = B * b * C6 * S10 - 2 * b * y9 - b^2 * y5
end

# %%
end # module GenerateData
