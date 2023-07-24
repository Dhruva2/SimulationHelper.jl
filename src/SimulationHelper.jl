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

# include("BasicUpdates.jl")

# export StateUpdate, Measurement, MovingCovarianceEstimator, OptimalKalmanGain, OptimalKalmanGain2, KalmanGainDiff, CumulativeSquaredError, ExternalFunctionUpdate

export summary

include("PlotBuilder.jl")


include("Particles.jl")

export Particle, ParticleCollection, ParticleWeightUpdate, Resampler, SystematicResampler

export states, weights, resampled
# export collection_average, collection_variance, get_particle_updates

include("SimulationStatistics.jl")

# export do_repeats, param_against_difference, param_against_summary, param_against_summary_repeated, 

end
