module CLASS

using Base: run
using DelimitedFiles
using DataFrames

format(x::Number) = string(x)
format(x::AbstractArray) = join(format.(x), ", ")
format(x::Bool) = x ? "yes" : "no"
format(x::String) = x
format(x::Symbol) = string(x)
format(x) = error("Don't know how to format type $(typeof(x))")

"""
    run(in::Dict; exec = "class", dir = mktempdir())

Run the CLASS executable `exec` (default: search `\$PATH`) in the directory `dir` (default: new temporary directory).
The input configuration `in` should be a dictionary from strings to values in the CLASS `.ini` format.
A dictionary is returned with all data tables stored in the output directory.

# Example

```julia-repl
julia> using CLASS

julia> in = Dict(
           "h" => 0.70,
           "output" => [:mPk, "tCl", "pCl"],
           "write_background" => true,
       );

julia> out = CLASS.run(in)
Dict{Any, Any} with 3 entries:
  "pk"         => 528×2 DataFrame…
  "cl"         => 2499×5 DataFrame…
  "background" => 40000×19 DataFrame…

julia> out["background"]
40000×19 DataFrame
   Row │ z           proper time [Gyr]  conf. time [Mpc]  H [1/Mpc]     ⋯
       │ Float64     Float64            Float64           Float64       ⋯
───────┼─────────────────────────────────────────────────────────────────
     1 │ 1.0e14            7.55952e-26        4.63479e-9  2.15726e22    ⋯
     2 │ 9.99194e13        7.57171e-26        4.63842e-9  2.15378e22
     3 │ 9.98389e13        7.58393e-26        4.64388e-9  2.15031e22
     4 │ 9.97585e13        7.59616e-26        4.64752e-9  2.14685e22
     5 │ 9.96781e13        7.60842e-26        4.65116e-9  2.14339e22    ⋯
     6 │ 9.95978e13        7.62069e-26        4.65479e-9  2.13994e22
   ⋮   │     ⋮               ⋮                 ⋮               ⋮        ⋱
 39996 │ 0.0032289        13.2951         13703.4         0.000233846
 39997 │ 0.0024207        13.3063         13706.8         0.000233758
 39998 │ 0.00161315       13.3176         13710.3         0.00023367    ⋯
 39999 │ 0.00080625       13.3288         13713.7         0.000233582
 40000 │ 0.0              13.3401         13717.2         0.000233495
                                        15 columns and 39989 rows omitted
```
"""
function Base.run(in::Dict; exec = "class", dir = mktempdir())
    # Set input and output paths
    inpath = joinpath(dir, "input.ini")
    outpath = joinpath(dir, "output/")

    # Output path should not exist from before
    isdir(outpath) && !isempty(readdir(outpath)) && error("Output directory $outpath is not empty")

    # Create input file
    in = merge(Dict("root" => outpath, "overwrite_root" => "yes"), in)
    in = sort(collect(in), by = first) # sort by key
    in = prod(["$key = $(format(val))\n" for (key, val) in in]) # make string with "key = val" lines
    mkpath(dirname(inpath))
    write(inpath, in)

    # Create output directory and run
    mkpath(dirname(outpath))
    run(`$exec $inpath`)

    # Return dictionary of output data tables
    out = Dict()
    for file in readdir(outpath)
        if startswith(file, "_") && endswith(file, ".dat")
            name = file[2:end-4]
            file = joinpath(outpath, file)
            out[name] = read_table(file)
        end
    end
    return out
end

# Construct a DataFrame from a CLASS formatted output table file
function read_table(file)
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
