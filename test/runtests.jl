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

@testset "Forbid setting root and overwrite_root" begin
    @test_throws "Do not set root or overwrite_root" CLASSProblem("root" => "./")
    @test_throws "Do not set root or overwrite_root" CLASSProblem("overwrite_root" => true)
end

@testset "Customize number of threads for parallelization" begin
    prob1, prob2, prob3 = copy(prob), copy(prob), copy(prob)
    sol1 = solve(prob1; threads = 1) # warmup
    sol2 = solve(prob2; threads = 1)
    sol3 = solve(prob3; threads = 4)
    @test sol3.runtime / sol2.runtime < 1/2 # should be at least 2x faster
end
