module NfmParamRanking

include("./GenerateData.jl")
include("./AnalyseResults.jl")

function main()
    GenerateData.main()
    AnalyseResults.main()
end

end # module NfmParamRanking
