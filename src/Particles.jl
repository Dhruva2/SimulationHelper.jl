""" 
Particle structs
"""

abstract type Particle <: Entity end

mutable struct ParticleCollection{P<:Entity, N<:Number} <: Entity
    particles::Vector{P}
    weights::Vector{N}
end


ParticleCollection(ps::Vector{P}) where {P<:Entity} = ParticleCollection(ps, ones(length(ps)) ./ length(ps))


states(pc::ParticleCollection) = [p.state for p in pc.particles]
weights(pc::ParticleCollection) = pc.weights

function collection_average(pc::ParticleCollection, f::Function)
    sum(zip(pc.particles, pc.weights)) do (p, w)
        f(p) * w
    end
end

# state(pc::ParticleCollection) = collection_average(pc, state)
# kalman_gain(pc::ParticleCollection) = collection_average(pc, kalman_gain)

function collection_variance(pc::ParticleCollection, f::Function)
    second_moment = sum(zip(pc.particles, pc.weights)) do (p, w)
        f(p)^2 * w
    end
    return second_moment - collection_average(pc, f)^2
end



function get_particle_updates(pc::ParticleCollection, interactions::Vector{Vector{T}}) where {T<:Specification}
    funcs, records = [p(interaction) for (p, interaction) in zip(pc.particles, interactions)] |> x -> (first.(x), last.(x))

    function func(args...)
        foreach(funcs) do f
            f(args...)
        end
        nothing
    end

    return func, records
end





# fundamentally different operations for updating LR vs SV particles 
struct ParticleWeightUpdate <: Interaction end

function (w::ParticleWeightUpdate)(time, pc::ParticleCollection, effected_updates, yₜ, args...)
    uw = unscaled_weights(pc.particles, yₜ)
    pc.weights = uw / norm(uw, 1)
    nothing
end





"""
Systematic resampling

generate a cdf from the weights: each point in the interval [0, 1] 
"""

abstract type Resampler <: Interaction end
struct SystematicResampler{N<:Number,I<:Integer,P<:Particle} <: Resampler
    particle_copies::Vector{P}
    bins::Vector{N}
    bin_positions::Vector{I}
    samples::Vector{N}
    cutoff::N
    resampled::typeof(Vector{Bool}(undef, 1))
end

function SystematicResampler(pc::ParticleCollection, cutoff)
    _N = length(pc.particles)
    T = eltype(pc.weights)
    return SystematicResampler(
        deepcopy(pc.particles),
        cumsum(pc.weights),
        Vector{Int64}(undef, _N),
        Vector{T}(undef, _N),
        cutoff,
        [false]
    )
end

resampled(s::SystematicResampler) = s.resampled[1]

function (s::SystematicResampler)(time, pc::ParticleCollection, effected_updates, yₜ, args...)

    Neff = 1.0 / sum(pc.weights .^ 2)
    _N = length(s.bins)

    if (Neff / _N) > s.cutoff
        # println("not resampling at time", time)
        s.resampled[1] = false
        return nothing
    else
        # @info "resampling at time  $time"
        s.resampled[1] = true
    end

    s.bins[:] = cumsum(pc.weights)

    if any(isnan.(s.bins))
        println(pc.weights)
    end

    # a lin range with a bit of jiggle
    map!(s.samples, 0:_N-1) do i
        return (i + rand(Uniform(0.0, 1.0))) / _N
    end

    # find the indices of the old samplers to map to the new samplers
    map!(s.bin_positions, s.samples) do m
        findfirst(1:_N) do i
            # (i == _N) && (println(m); println(s.bins[end]))
            if i == 1
                return m < s.bins[i]
            else
                return (m > s.bins[i-1]) && (m < s.bins[i])
            end
        end
    end

    retained_particles_indxs = unique(s.bin_positions)
    num_retained_particles = length(retained_particles_indxs)
    which_retained_p(i::Int64) = findfirst(x -> x == s.bin_positions[i], retained_particles_indxs)
    # i -> bin_position[i] -> which element of unique is bin_positions[i]

    for (copy, particle) in zip(s.particle_copies[1:num_retained_particles], pc.particles[retained_particles_indxs])
        provide!(copy, particle)
    end

    for (i, particle) in enumerate(pc.particles)
        provide!(particle, s.particle_copies[which_retained_p(i)])
    end

    # @info "new particles spawned from $(length(unique(s.bin_positions))), new particles"
    nothing
end
