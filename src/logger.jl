using Eterm
using Logging

struct ElixirLogger <: AbstractLogger
    min_level::LogLevel
    message_limits::Dict{Any,Int}
end

ElixirLogger(level=Logging.Info) = ElixirLogger(level, Dict{Any,Int}())

Logging.shouldlog(logger::ElixirLogger, level, _module, group, id) =
    get(logger.message_limits, id, 1) > 0

Logging.min_enabled_level(logger::ElixirLogger) = logger.min_level

Logging.catch_exceptions(logger::ElixirLogger) = false

function Logging.handle_message(logger::ElixirLogger, level, message, _module, group, id,
                        filepath, line; maxlog=nothing, kwargs...)
    if maxlog != nothing && maxlog isa Integer
        remaining = get!(logger.message_limits, id, maxlog)
        logger.message_limits[id] = remaining - 1
        remaining > 0 || return
    end
    buf = IOBuffer()
    levelstr = level == Logging.Warn ? "Warning" : string(level)
    msglines = split(chomp(string(message)), '\n')
    println(buf, "┌ ", levelstr, ": ", msglines[1])
    for i in 2:length(msglines)
        println(buf, "│ ", msglines[i])
    end
    for (key, val) in kwargs
        println(buf, "│   ", key, " = ", val)
    end
    println(buf, "└ @ ", something(_module, "nothing"), " ",
            something(filepath, "nothing"), ":", something(line, "nothing"))

    msg = String(take!(buf))
    serialize(buf, (:log, msg))
    isopen(stdout) && write(stdout, take!(buf))
    nothing
end
