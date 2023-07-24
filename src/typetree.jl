"""
basic types
"""

using LinearAlgebra, Distributions, Random
import Base.==, Base.Pair, Base.getindex, Base.show


abstract type Thing end
abstract type Entity <: Thing end
abstract type Interaction <: Thing end
abstract type Specification end
abstract type AbstractRecorder end






####################################

