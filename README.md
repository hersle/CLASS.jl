# CLASS.jl

A simple Julia wrapper for the cosmological Boltzmann solver [CLASS](http://class-code.net/) that reads its output as [DataFrames](https://github.com/JuliaData/DataFrames.jl).

## Installation

```julia-repl
julia> using Pkg; Pkg.add("CLASS")
```

This installs the wrapper, but not the CLASS code itself. Install whichever version of CLASS you want to run yourself!

## Usage

Call `CLASS.run(in)`, where `in` is a key-value dictionary that matches the [CLASS .ini format](https://github.com/lesgourg/class_public/blob/master/explanatory.ini).
To customize the `class` executable path or set the directory for generated input and output files, enter `?` and see `help?> CLASS.run`.

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
