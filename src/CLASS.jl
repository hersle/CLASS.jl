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
