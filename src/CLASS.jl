module CLASS

using CommonSolve
using CommonSolve: solve
using DelimitedFiles
using DataFrames

export CLASSProblem, CLASSSolution, solve

struct CLASSProblem
    in::Dict
    inpath::String
    outpath::String

    @doc """
        CLASSProblem(args...; dir = mktempdir())

    Create a problem for running CLASS with input (.ini) configuration file created by key-value mapping `args...`.
    The run will be performed in the directory `dir`.
    """
    function CLASSProblem(args...; dir = mktempdir()) # overwrite default constructor
        inpath = joinpath(dir, "input.ini")
        outpath = joinpath(dir, "output/")

        in = Dict(args...)
        in = merge(Dict("root" => outpath, "overwrite_root" => "yes"), in)
        in = Dict(sort(collect(in), by = first)) # sort by key

        return new(in, inpath, outpath)
    end
end

struct CLASSSolution
    prob::CLASSProblem
    tables::Dict{String, Union{Nothing, DataFrame}}
    runtime::Number
end

format_CLASS(x::Number) = string(x)
format_CLASS(x::AbstractArray) = join(format_CLASS.(x), ", ")
format_CLASS(x::Bool) = x ? "yes" : "no"
format_CLASS(x::String) = x
format_CLASS(x::Symbol) = string(x)
format_CLASS(x) = error("Don't know how to format type $(typeof(x))")

input(prob::CLASSProblem) = prod(["$key = $(format_CLASS(val))\n" for (key, val) in prob.in]) # make string with "key = val" lines
Base.show(io::IO, prob::CLASSProblem) = print(io, "CLASS problem with input file $(prob.inpath):\n", input(prob)[begin:end-1]) # exclude final newline

"""
    solve(prob::CLASSProblem; exec = "class")

Solve the CLASS problem `prob` with the CLASS executable `exec` (default: search `\$PATH`).
A CLASS solution object is returned that lazily loads all output tables produced by CLASS.

# Example

```julia-repl
julia> using CLASS

julia> prob = CLASSProblem(
           "h" => 0.70,
           "output" => [:mPk, "tCl", "pCl"],
           "write_background" => true,
       );

julia> sol = solve(prob)
CLASS solution with tables:
  pk: unread (lazily loaded)
  cl: unread (lazily loaded)
  background: unread (lazily loaded)

julia> sol["background"]
40000×19 DataFrame
   Row │ z           proper time [Gyr]  conf. time [Mpc]  H [1/Mpc]   ⋯
       │ Float64     Float64            Float64           Float64     ⋯
───────┼───────────────────────────────────────────────────────────────
     1 │ 1.0e14            7.55952e-26        4.63479e-9  2.15726e22  ⋯
     2 │ 9.99194e13        7.57171e-26        4.63842e-9  2.15378e22
     3 │ 9.98389e13        7.58393e-26        4.64388e-9  2.15031e22
     4 │ 9.97585e13        7.59616e-26        4.64752e-9  2.14685e22
     5 │ 9.96781e13        7.60842e-26        4.65116e-9  2.14339e22  ⋯
     6 │ 9.95978e13        7.62069e-26        4.65479e-9  2.13994e22
   ⋮   │     ⋮               ⋮                 ⋮               ⋮      ⋱
 39996 │ 0.0032289        13.2951         13703.4         0.000233846
 39997 │ 0.0024207        13.3063         13706.8         0.000233758
 39998 │ 0.00161315       13.3176         13710.3         0.00023367  ⋯
 39999 │ 0.00080625       13.3288         13713.7         0.000233582
 40000 │ 0.0              13.3401         13717.2         0.000233495
                                      15 columns and 39989 rows omitted
```
"""
function CommonSolve.solve(prob::CLASSProblem; exec = "class")
    # Output path should not exist from before
    isdir(prob.outpath) && !isempty(readdir(prob.outpath)) && error("Output directory $(prob.outpath) is not empty")

    # Create input file
    mkpath(dirname(prob.inpath))
    write(prob.inpath, input(prob))

    # Create output directory and run
    mkpath(dirname(prob.outpath))
    runtime = @elapsed run(`$exec $(prob.inpath)`)

    # Return dictionary of output data tables
    tables = Dict()
    for file in readdir(prob.outpath)
        if startswith(file, "_") && endswith(file, ".dat")
            name = file[2:end-4]
            tables[name] = nothing
        end
    end
    return CLASSSolution(prob, tables, runtime)
end

function Base.show(io::IO, sol::CLASSSolution)
    print(io, "CLASS solution (ran in $(sol.runtime) seconds) with tables:")
    for (name, table) in sol.tables
        printstyled(io, "\n  $name: "; bold = true)
        if isnothing(table)
            print(io, "unread (lazily loaded)")
        else
            print(io, join(size(table), "x"), " numbers")
        end
    end
end

function Base.getindex(sol::CLASSSolution, name::String)
    name in keys(sol.tables) || error("CLASS solution does not have a table named $name")
    table = sol.tables[name]
    if isnothing(table)
        tablepath = joinpath(sol.prob.outpath, "_$name.dat")
        table = read_table_CLASS(tablepath)
        sol.tables[name] = table
    end
    return table
end
Base.getindex(sol::CLASSSolution, name::Symbol) = Base.getindex(sol, string(name))

# Construct a DataFrame from a CLASS formatted output table file
function read_table_CLASS(file)
    # Find the header, which is the last line that starts with #
    header = ""
    for line in eachline(file)
        !startswith(line, "#") && break
        header = line
    end

    # Extract column names
    header = strip(header, [' ', '#'])
    head = split(header, r"\s\s+") # 2+ spaces
    head = map(h -> split(h, ':')[2], head)

    # Read and return data as a DataFrame
    data = readdlm(file; comments = true) # skip comments

    return DataFrame(data, head)
end

end
