"""

- You can record an interaction or an entity
 Requirements

 interactions have a functor:

 int(time, to_whom, args, kwargs)

"""

module SimulationHelper

# Write your package code here.
using Statistics
using LinearAlgebra, Distributions, Random

using LinearAlgebra, Distributions, Random
import Base.getindex, Base.show




include("SimpleInteraction.jl")
export RecordedUpdate, SimpleRecorder, CompositeRecord, compose_updates


end
