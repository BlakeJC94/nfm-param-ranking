module NfmParamRanking

include("./GenerateData.jl")
include("./AnalyseResults.jl")

function main()
    data, labels = GenerateData.main()
    output = AnalyseResults.main(data)
end

end # module NfmParamRanking
