"""
Notes:

renamed time(::Interaction) and time(::InteractionSpecification) as _time

exported Base.Pair

not importing/exporting Base.==  as it will only be used internally in the module

might need 
import Base.getindex


"""

module SimulationHelper

# Write your package code here.
using Statistics
using LinearAlgebra, Distributions, Random

include("typetree.jl")
export Thing, Entity, Interaction, Specification, AbstractRecorder

requirements(::Thing) = ()
name(T::Thing) = nameof(T |> typeof)


import Base.Pair, Base.show #I'm a type pirate

include("InteractionSpecification.jl")

export InteractionSpecification, ObservationSpecification, Record

export requirements

include("UpdateBuilder.jl")

include("RecordBuilder.jl")

export Recorder, name, get_record, difference

include("PlotBuilder.jl")


end
