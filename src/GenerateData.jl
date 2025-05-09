module GenerateData

# %%
using QuasiMonteCarlo, Random, LinearAlgebra, DifferentialEquations, FFTW, Peaks, Parameters

@with_kw struct ParameterRange
    name::Symbol
    min::Float64
    max::Float64
end

@with_kw struct SimulationConfig
    T0::Float64  # Transient end time (discard signal up to this t value)
    T::Float64   # Max simulation time
    Fs::Float64  # Sampling frequency
end

@with_kw struct Config
    N::Int64
    simulation_config::SimulationConfig
    param_ranges::Vector{ParameterRange}
end


function main(config::Config)::Tuple{Matrix{Real}, Matrix{Real}, Vector{Vector{Float64}}}
    @info "Generating parameter space"
    param_configs = generate_hypercube(
        config.param_ranges,
        config.N
    )

    @info "Solving model for each configuration"
    solutions = []
    data = []
    for i = 1:N
        if i % 100 == 0
            @info "sim $(i)"
        end
        Y = solve_eq(
            jansen_ritt_wendling!,
            param_configs[i, :],
            config.simulation_config,
        )
        characteristics = extract_characteristics(Y, config.simulation_config)
        push!(solutions, Y)
        push!(data, characteristics)
    end

    @info "labelling simluations"
    data = reduce(vcat, [collect(t)' for t in data])
    seizure = discretize(data[:,3], [0, 1.1, 10000])
    steadystate = discretize(data[:,1], [0, 0.1, 10000])

    labels = hcat(data, seizure, steadystate)
    return param_configs, labels, simulations
end

# %%

function spect(
    Y::AbstractVector{<:Real},
)::AbstractVector{<:Real}
    L = length(Y)
    S = fft(Y)

    P2 = abs.(S/L)

    P1 = P2[1:floor(Int, L/2)+1]
    P1[2:end-1] = 2*P1[2:end-1]
    return P1
end

function get_peaks_filtered_fallback(
    data::AbstractVector{<:Real},
    min_height::Real,
)::Tuple{Vector{<:Integer}, Vector{<:Real}}
    inds, heights = findmaxima(data)
    if any(heights .> min_height)
        inds, heights = peakheights(inds, heights; min=min_height)
    end
    return inds, heights
end

function extract_characteristics(
    Y::Vector{Float64},
    simulation_config::SimulationConfig,
)::Tuple{Real, Real, Real}
    Fs, T0, T = simulation_config.Fs, simulation_config.T0, simulation_config.T

    L = length(Y)
    P1 = spect(Y)
    amplitude = maximum(Y) - minimum(Y)
    if amplitude < 0.1
        frequency = 0.1
        peaks = 0
        return amplitude, frequency, peaks
    end

    min_height = maximum(P1[2:end]) / 10
    inds, _ = get_peaks_filtered_fallback(P1, min_height)
    index_max = inds[1]
    frequency = index_max * (Fs/L)

    peaks = length(maxima(Y)) / (frequency * (T - T0));

    rem = peaks - floor(peaks)
    if 0.2 < rem < 0.8
        min_height = maximum(P1[2:end]) / 50
        inds, _ = get_peaks_filtered_fallback(P1, min_height)
        index_max = inds[1]
        frequency = index_max * (Fs/L)
    end

    if frequency < 0.11
        peaks = 0
    end

    return amplitude, frequency, peaks
end

# %%

function solve_eq(
    func::Function,
    param_config::Vector{Float64},
    simulation_config::SimulationConfig,
)::Vector{Float64}
    Fs, T0, T = simulation_config.Fs, simulation_config.T0, simulation_config.T
    dt = 1 / Fs  # Sampling period
    y0 = zeros(length(param_config), 1)  # Initial conditions

    prob = ODEProblem(func, y0, (0, T), param_config)
    sol = solve(prob, DP5(), dt=dt, adaptive=false)

    start_idx = Int(T0 * Fs)
    y = sol[2,:] - sol[3,:] - sol[4,:]
    return y[start_idx:end]
end

# %%

"""
    generate_hypercube(N::Int, d::Int, min_max_vals::AbstractArray{Float64,2})::Matrix{Float64}

Generate a random Latin Hypercube with `N` points embedded in `d` dimensions within the ranges
specified by the `(2 x d)` matrix `min_max_vals`.
"""
function generate_hypercube(
    param_ranges::Vector{ParameterRange},
    N::Int64,
)::Matrix{Float64}
    d = length(param_ranges)

    min_vals = getfeld.(param_ranges, :min)
    max_vals = getfeld.(param_ranges, :max)

    range = max_vals - min_vals
    @assert all(range .> 0)

    scale = diagm(range)

    sampler = QuasiMonteCarlo.LatinHypercubeSample()
    res = QuasiMonteCarlo.sample(N, d, sampler)

    return transpose(min_vals .+ scale * res)
end

function discretize(
    data::AbstractVector{T},
    edges::AbstractVector{T},
)::AbstractVector{T} where T<:Real
    return [searchsortedlast(edges, x) for x in data] .- 1
end

"""
    sig(v, v0, e0, r)

A sigmoid function that relates the average postsynaptic potential of a given population to an
average pulse density of action potentials outgoing from the population.
"""
function sig(v::T, v0::T, e0::T, r::T)::T where T<:Real
    return 2 * e0 / (1 + exp(r * (v0 - v)))
end


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
function jansen_ritt_wendling!(
    dy::AbstractVector{T},
    y::AbstractVector{T},
    p::AbstractVector{T},
    t::T,
)::AbstractVector{T} where {T <: Real}
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
end # module Generate Data
