module Types
export ParameterRange, SimulationConfig, ModelConfig, Config

using Parameters

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

@with_kw struct ModelConfig
    name::String
    labels::Vector{Real}
    model_type::Function
    model_args::Dict{String, Any}
end

end  # module Types
