module NfmParamRanking

include("./GenerateData.jl")
include("./AnalyseResults.jl")

function main()
    param_configs, labels = GenerateData.main()
    output = AnalyseResults.main(param_configs, labels)
end

end # module NfmParamRanking
