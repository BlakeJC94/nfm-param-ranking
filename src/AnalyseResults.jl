module AnalyseResults

using DecisionTree
using ..Types

function main(
    config::Config,
    model_configs::Vector{ModelConfig},
    param_configs::Matrix{Real},
)::Dict{String, Vector{Tuple{String, Float64}}}
    println("BAZ!")

    feature_names = [string(p.name) for p in config.param_ranges]

    results = Dict()
    for config in model_configs
        name, model_type, model_args = config.name, config.model_type, config.model_args

        @info "Fitting model for $name"
        model = model_type(model_args...)
        fit!(model, param_configs, label)

        @info "Calculating importances"
        importances = impurity_importance(model)
        importances_normalized = importances / maximum(importances)
        result = sort(collect(zip(feature_names, importances_normalized)); by=last, rev=true)

        results[name] = result
    end

    return results
end

end # module AnalyseResults
