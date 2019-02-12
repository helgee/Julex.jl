using Julex
using ErlangTerm
using Test

julia = joinpath(Sys.BINDIR, "julia")
project = joinpath(@__DIR__, "..")


cmd = `$julia --startup-file=no --project=$project -e 'using Julex; Julex.execute(::Val{:echo}, params) = params; Julex.run_loop()'`

@testset "Julex" begin
    payload = Dict(:id=>1, :method=>:echo, :params=>["Hello, Julex!"])
    f = open(cmd, "r+")
    binary = serialize(payload)
    write(f, binary)
    close(f.in)
    response = deserialize(read(f))
    @test response == Dict(:id=>1, :result=>["Hello, Julex!"])
end
