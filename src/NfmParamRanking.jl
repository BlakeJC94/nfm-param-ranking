module NfmParamRanking

include("./Types.jl")
include("./GenerateData.jl")
include("./AnalyseResults.jl")

using CSV
using DataFrames
using DecisionTree
using FileIO
using HDF5

using .Types
using .GenerateData

function main()
    results_path = "./results.h5"
    output_path = "./output.csv"

    config = Config(
        N=5,  # TODO  2_000_000
        simulation_config=SimulationConfig(
            T0=10.0,
            T=20.0,
            Fs=500.0,
        ),
        param_ranges=[
            ParameterRange(:A, 0.0, 10.0),
            ParameterRange(:B, 0.0, 50.0),
            ParameterRange(:G, 0.0, 50.0),
            ParameterRange(:P, 0.0, 2000.0),
            ParameterRange(:a, 25.0, 140.0),
            ParameterRange(:b, 6.5, 110.0),
            ParameterRange(:g, 350.0, 650.0),
            ParameterRange(:c, 0.0, 1350.0),
            ParameterRange(:v_0, 2.0, 9.0),
            ParameterRange(:e_0, 0.5, 7.5),
            ParameterRange(:r, 0.3, 0.8),
        ],
    )

    if isfile(results_path)
        loaded_config, param_configs, labels, simulations = load_results(results_path)
        if loaded_config != config
            @error "Loaded config doesn't match defined config"
            return
        end
    else
        param_configs, labels, simulations = GenerateData.main(config)
        save_results(
            results_path,
            config,
            param_configs,
            labels,
            simulations,
        )
    end

    output = AnalyseResults.main(
        config,
        [
            ModelConfig(
                name="seizure",
                labels=labels[:,4],
                model_type=RandomForestClassifier,
                model_args=Dict(
                     :n_trees=>100,
                     :min_samples_leaf=>2000,
                     :impurity_importance=>true,
                ),
            ),
            ModelConfig(
                name="steady_state",
                labels=labels[:,5],
                model_type=RandomForestClassifier,
                model_args=Dict(
                     :n_trees=>100,
                     :min_samples_leaf=>2000,
                     :impurity_importance=>true,
                ),
            ),
            ModelConfig(
                name="amplitude",
                labels=labels[:,1],
                model_type=RandomForestRegressor,
                model_args=Dict(
                     :n_trees=>100,
                     :min_samples_leaf=>2000,
                     :impurity_importance=>true,
                ),
            ),
            ModelConfig(
                name="frequency",
                labels=labels[:,2],
                model_type=RandomForestRegressor,
                model_args=Dict(
                     :n_trees=>100,
                     :min_samples_leaf=>2000,
                     :impurity_importance=>true,
                ),
            ),
        ],
        param_configs,
    )

    # print results
    print_output(output)

    # save results
    table = DataFrame([(; name=name, (Symbol(k) => v for (k, v) in result)...) for (name, result) in output])
    CSV.write(output_path, table)
end

# TODO utils
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

# TODO utils
function save_results(
    results_path::String,
    config::Config,
    param_configs::Matrix{Real},,
    labels::Matric{Real},
    simulations::Vector{Vector{Float64}},
)
    h5open(results_path, "w") do file
        file["param_configs"] = param_configs
        file["labels"] = labels
        sim_group = create_group(file, "simulations")

        n_digits = length(string(length(simulations)))
        for (i, sim) in enumerate(simulations)
            sim_group[@sprintf("%0*d", n_digits, i)] = sim
        end

        g = create_group(h5file, "config")

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
end

# TODO utils
function load_results(
    results_path::str,
)::Tuple{Config, Matrix{Real}, Matrix{Real}, Vector{Vector{Float64}}}
    @info "loading results"

    param_configs = Matrix{Float64}(undef, 0, 0)
    labels = Matrix{Float64}(undef, 0, 0)
    simulations = Vector{Vector{Float64}}()

    h5open(results_path, "r") do file
        param_configs = read(file["param_configs"])
        labels = read(file["labels"])

        sim_group = file["simulations"]
        n_sims = length(keys(sim_group))
        simulations = Vector{Vector{Float64}}(undef, n_sims)

        for (i, name) in enumerate(sort(collect(keys(sim_group))))
            simulations[i] = read(sim_group[name])
        end
    end

    g = h5file["config"]

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

    config = Config(N=N, simulation_config=sim_config, param_ranges=param_ranges)
    return config, param_configs, labels, simulations
end

end # module NfmParamRanking
