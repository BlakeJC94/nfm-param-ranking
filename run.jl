using Pkg
Pkg.activate(".")

using NfmParamRanking

function main()
    NfmParamRanking.main()
end

if !isdefined(Base, :active_repl)
    main()
end
