module Utils
export print_output, save_results, load_results

using FileIO
using HDF5

using ..Types

function print_output(output::Dict{String, Vector{Tuple{String,Float64}}})
    for (name, result) in output
        println(name)
        println("-"^length(name))
        ranking = sort(result; by=last, rev=true)
        for (param, score) in ranking
            println("  ", rpad(param, 8), round(score, digits=4))
        end
        println()
    end
end



function save_config(file::HDF5.File, config::Config)
    g = create_group(file, "config")

    g["N"] = config.N
    g["simulation/T0"] = config.simulation_config.T0
    g["simulation/T"]  = config.simulation_config.T
    g["simulation/Fs"] = config.simulation_config.Fs

    # Store parameter ranges as a dataset of strings/floats
    names = [string(p.name) for p in config.param_ranges]
    mins = [p.min for p in config.param_ranges]
    maxs = [p.max for p in config.param_ranges]

    g["param_ranges/names"] = names
    g["param_ranges/mins"] = mins
    g["param_ranges/maxs"] = maxs
end

function save_simulations(file::HDF5.File, simulations::Vector{Vector{Float64}})
    sim_group = create_group(file, "simulations")

    n_digits = length(string(length(simulations)))
    for (i, sim) in enumerate(simulations)
        sim_group[lpad(i,n_digits,"0")] = sim
    end
end

function save_results(
    results_path::String,
    config::Config,
    param_configs::Matrix{Float64},
    labels::Matrix{Float64},
    simulations::Vector{Vector{Float64}},
)
    h5open(results_path, "w") do file
        file["param_configs"] = param_configs
        file["labels"] = labels
        save_simulations(file, simulations)
        save_config(file, config)
    end
end

function load_config(file::HDF5.File)::Config
    g = file["config"]

    N = read(g["N"])
    T0 = read(g["simulation/T0"])
    T = read(g["simulation/T"])
    Fs = read(g["simulation/Fs"])
    sim_config = SimulationConfig(T0=T0, T=T, Fs=Fs)

    names = Symbol.(read(g["param_ranges/names"]))
    mins = read(g["param_ranges/mins"])
    maxs = read(g["param_ranges/maxs"])

    param_ranges = [ParameterRange(name=names[i], min=mins[i], max=maxs[i])
                    for i in eachindex(names)]

    return Config(N=N, simulation_config=sim_config, param_ranges=param_ranges)
end

function load_simulations(file::HDF5.File)::Vector{Vector{Float64}}
    sim_group = file["simulations"]
    n_sims = length(keys(sim_group))
    simulations = Vector{Vector{Float64}}(undef, n_sims)

    for (i, name) in enumerate(sort(collect(keys(sim_group))))
        simulations[i] = read(sim_group[name])
    end
    return simulations
end


function load_results(
    results_path::String,
)::Tuple{Config, Matrix{Float64}, Matrix{Float64}, Vector{Vector{Float64}}}
    @info "loading results"
    config, param_configs, labels, simulations = h5open(results_path, "r") do file
        param_configs = read(file["param_configs"])
        labels = read(file["labels"])
        simulations = load_simulations(file)
        config = load_config(file)
        return config, param_configs, labels, simulations
    end
    return config, param_configs, labels, simulations
end

end  # module Utils
