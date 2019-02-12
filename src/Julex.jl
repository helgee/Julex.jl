module Julex

using ErlangTerm

include("logger.jl")

global_logger(ElixirLogger())

function execute end

function run_loop()
    while !eof(stdin)
        req = deserialize(stdin)
        id = req[:id]
        method = req[:method]
        params = req[:params]
        result = Dict()
        try
            value = execute(Val(method), params)
            merge!(result, Dict(:id=>id, :result=>value !== nothing ? value : :nil))
        catch err
            bt = catch_backtrace()
            @error "Julia Worker caught an exception." excpetion=(err, bt)
            merge!(result, Dict(:id=>id, :error=>string(err)))
        end
        buf = IOBuffer()
        serialize(buf, result)
        isopen(stdout) && write(stdout, take!(buf))
    end
end

end # module
