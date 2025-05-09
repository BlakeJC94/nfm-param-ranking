module AnalyseResults

using DecisionTree
using ..Types

function main(
    config::Config,
    model_configs::Vector{ModelConfig},
    param_configs::Matrix{Float64},
)::Dict{String, Vector{Tuple{String, Float64}}}
    feature_names = [string(p.name) for p in config.param_ranges]

    results = Dict()
    for model_config in model_configs
        name, model_type, model_args = model_config.name, model_config.model_type, model_config.model_args
        label = model_config.labels

        @info "Fitting model for '$name'"
        model = model_type(;model_args...)
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
