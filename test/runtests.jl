using CLASS, Test

in = Dict(
    "h" => 0.70,
    "output" => [:mPk, "tCl", "pCl"],
    "write_background" => true,
)

@testset "Standard usage" begin
    out = CLASS.run(in)
    @test haskey(out, "pk")
    @test haskey(out, "cl")
    @test haskey(out, "background")
end

@testset "Error when executable is not found" begin
    @test_throws Base.IOError CLASS.run(in; exec = "fuck")
end

@testset "Forbid repeated usage in the same directory" begin
    dir = mktempdir()
    @test CLASS.run(in; dir) isa Any # success
    @test_throws "is not empty" CLASS.run(in; dir) isa Any # failure
end
