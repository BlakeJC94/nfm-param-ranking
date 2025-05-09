module NfmParamRanking

include("./GenerateData.jl")
include("./AnalyseResults.jl")

using .GenerateData: Config, SimulationConfig, ParameterRange

function main()
    config = Config(
        N=5,  # 2_000_000
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

    param_configs, labels, simulations = GenerateData.main(config)
    output = AnalyseResults.main(param_configs, labels)
end

end # module NfmParamRanking
