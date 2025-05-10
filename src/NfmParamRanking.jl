module NfmParamRanking

include("./Types.jl")
include("./AnalyseResults.jl")
include("./GenerateData.jl")
include("./Utils.jl")

using CSV
using DataFrames
using DecisionTree
using Random

using .Types
using .AnalyseResults
using .GenerateData
using .Utils

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
                model_type=RandomForestClassifier,
                model_args=Dict(
                     :n_trees=>100,
                     :min_samples_leaf=>2000,
                     :impurity_importance=>true,
                ),
            ),
            ModelConfig(
                name="steady_state",
                model_type=RandomForestClassifier,
                model_args=Dict(
                     :n_trees=>100,
                     :min_samples_leaf=>2000,
                     :impurity_importance=>true,
                ),
            ),
            ModelConfig(
                name="amplitude",
                model_type=RandomForestRegressor,
                model_args=Dict(
                     :n_trees=>100,
                     :min_samples_leaf=>2000,
                     :impurity_importance=>true,
                ),
            ),
            ModelConfig(
                name="frequency",
                model_type=RandomForestRegressor,
                model_args=Dict(
                     :n_trees=>100,
                     :min_samples_leaf=>2000,
                     :impurity_importance=>true,
                ),
            ),
        ],
        param_configs,
        labels,
    )

    # print results
    print_output(output)

    # save results
    table = DataFrame([(; name=name, (Symbol(k) => v for (k, v) in result)...) for (name, result) in output])
    CSV.write(output_path, table)
end

end # module NfmParamRanking
