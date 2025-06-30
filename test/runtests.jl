using CLASS, Test

prob = CLASSProblem(
    "h" => 0.70,
    "output" => [:mPk, "tCl", "pCl"],
    "write_background" => true,
)

@testset "Error when executable is not found" begin
    @test_throws Base.IOError solve(prob; exec = "fuck")
end

@testset "Standard usage" begin
    sol = solve(prob)
    @test Set(keys(sol.tables)) == Set(["pk", "cl", "background"])
end

@testset "Forbid repeated usage in the same directory" begin
    try
        solve(prob) isa Any # fill directory if not already filled (ignoring error)
    catch
    end
    @test_throws "is not empty" solve(prob) isa Any # failure
end
