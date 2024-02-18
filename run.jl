using NfmParamRanking

function main()
    NfmParamRanking.greet()
end

if !isdefined(Base, :active_repl)
    main()
end
