module AnalyseResults

using DecisionTree
using DataFrames
using Random

using ..Types

function main(
    config::Config,
    model_configs::Vector{ModelConfig},
    param_configs::DataFrame,
    labels::DataFrame,
)::Dict{String, Vector{Tuple{String, Float64}}}
    Random.seed!(1234)

    param_configs.r_AB = param_configs.A ./ param_configs.B
    param_configs.r_ab = param_configs.a ./ param_configs.b

    feature_names = names(param_configs)
    param_configs = Matrix(param_configs)
    results = Dict()
    for model_config in model_configs
        name, model_type, model_args = model_config.name, model_config.model_type, model_config.model_args
        label = labels[:, name]

        @info "Fitting model for '$name'"
        model = model_type(;model_args...)
        fit!(model, param_configs, label)
        importances = impurity_importance(model)
        importances_normalized = importances / maximum(importances)

        results[name] = collect(zip(feature_names, importances_normalized))
    end

    return results
end

end # module AnalyseResults
