module Types
export ParameterRange, SimulationConfig, ModelConfig, Config

import Base: ==

using Parameters

@with_kw struct ParameterRange
    name::Symbol
    min::Float64
    max::Float64
end

function ==(a::ParameterRange, b::ParameterRange)
    a.name == b.name && a.min == b.min && a.max == b.max
end

@with_kw struct SimulationConfig
    T0::Float64  # Transient end time (discard signal up to this t value)
    T::Float64   # Max simulation time
    Fs::Float64  # Sampling frequency
end

function ==(a::SimulationConfig, b::SimulationConfig)
    a.T0 == b.T0 && a.T == b.T && a.Fs == b.Fs
end

@with_kw struct Config
    N::Int64
    simulation_config::SimulationConfig
    param_ranges::Vector{ParameterRange}
end

function ==(a::Config, b::Config)
    a.N == b.N &&
    a.simulation_config == b.simulation_config &&
    a.param_ranges == b.param_ranges
end


@with_kw struct ModelConfig
    name::String
    model_type::Any
    model_args::Dict{Symbol, Any}
end

end  # module Types
