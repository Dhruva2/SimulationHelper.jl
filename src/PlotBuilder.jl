#  using RecipesBase

# @recipe f(::Type{MyVec}, myvec::MyVec) = myvec.v

"""
plot(record, what) where what is a function that is applied to summary
commenting this out as using Makie for now, and don't want to import RecipesBase
"""

# RecipesBase.@recipe function f(r::Recorder, what=x -> x)
#     x = r.times
#     y = what.(r.summary)
#     label --> String(name(r))
#     xlabel --> "times"
#     x, y
# end





# function AbstractPlotting.plot!(Plot(Recorder))
#     r = to_value(p[1])
#     lines!(p, r.times, r.summary)
# end

# MakieCore.convert_arguments(r::Recorder) = (r.times, r.summary) 

