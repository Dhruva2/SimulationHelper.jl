"""
State update and measurement structs for general use.
    Add specific methods for entity subtypes
"""

mutable struct StateUpdate{L} <: Interaction
    last::L
end
mutable struct Measurement{L} <: Interaction
    last::L
end

observation() = nothing
state() = nothing


StateUpdate(env::Entity) = StateUpdate(env |> state)
Measurement(env::Entity) = Measurement(env |> observation)

summary(s::StateUpdate) = s.last
summary(m::Measurement) = m.last


mutable struct MovingCovarianceEstimator{N<:Number} <: Interaction
    mse::N
    cov::N
    innov::N
end
MovingCovarianceEstimator(; innov=5.0) = MovingCovarianceEstimator(0.0, 1.0, innov)
summary(m::MovingCovarianceEstimator) = m.cov

function (m::MovingCovarianceEstimator)(time, learner::Entity, effected_updates, yₜ, args...; kwargs...)
    λ = 1.0 / m.innov
    m.mse = (1.0 - λ) * m.mse + λ * (
        (sum(abs2, yₜ - state(learner)))
    )
    m.cov = m.mse - stochasticity(learner)
end


"""
We use OptimalKalmanGain instead of OptimalKalmanGain2 because the low pass filter irons out a lot of fluctuations. 
"""
mutable struct OptimalKalmanGain{E<:Entity,N<:Number} <: Interaction
    env::E
    last::N
    cov::N
    innov::N
end
OptimalKalmanGain(env::Entity; innov=5.0) = OptimalKalmanGain(env, 0.0, 0.0, innov)

"""
1. low pass filters squared error of learner and environmental states, to give an estimate of covariance
2. puts this covariance estimate into the the formula for kalman gain, along with true environmental volatility /stochasticity
"""
function (k::OptimalKalmanGain)(time, learner::Entity, effected_updates, args...; kwargs...)
    env = k.env
    λ = 1.0 / k.innov
    k.cov = (1.0 - λ) * k.cov + λ * (sum(abs2, state(learner) - state(k.env)))
    k.last = (k.cov + volatility(env)) / (k.cov + volatility(env) + stochasticity(env))
    nothing
end
summary(k::OptimalKalmanGain) = k.last


mutable struct OptimalKalmanGain2{E<:Entity, N<:Number} <: Interaction
    env::E
    last::N
end

function (k::OptimalKalmanGain2)(time, learner::Entity, effected_updates, args...; kwargs...)
    env = k.env 
    cov = sum(abs2, state(env) - state(learner))
    k.last = (cov + volatility(env)) / (cov + volatility(env) + stochasticity(env))
    nothing
end
OptimalKalmanGain2(env::Entity) = OptimalKalmanGain2(env, 0.0)
summary(k::OptimalKalmanGain2) = k.last

mutable struct KalmanGainDiff{L,O<:OptimalKalmanGain} <: Interaction
    okg::O
    last::L
end
KalmanGainDiff(okg::OptimalKalmanGain) = KalmanGainDiff(okg, 0.0)

function (k::KalmanGainDiff)(time, learner::Entity, effected_updates, args...; kwargs...)
    k.okg(time, learner, effected_updates, args...)
    k.last = k.okg.last - kalman_gain(learner)
    nothing
end

summary(k::KalmanGainDiff) = k.last

mutable struct CumulativeSquaredError{E<:Entity,N<:Number, F<:Function} <: Interaction
    env::E
    of_what::F
    error::N
    divide_by::N
end

CumulativeSquaredError(env::Entity; divide_by=1.0) = CumulativeSquaredError(env, state, 0.0, divide_by)
CumulativeSquaredError(env::Entity, of_what::Function; divide_by=1.0) = CumulativeSquaredError(env, of_what, 0.0, divide_by)


function (c::CumulativeSquaredError)(time, learner::Entity, effected_updates, args...; kwargs...)
    n = c.divide_by
    env = c.env
    c.error += (1.0 / n) * sum(abs2, c.of_what(env) - c.of_what(learner))
    nothing
end
summary(c::CumulativeSquaredError) = c.error

"""
change_func(t) gives the change to apply_to(env) at time t. The change NOT the actual value
"""
mutable struct ExternalFunctionUpdate{F1<:Function,L} <: Interaction
    change_func::F1
    apply_to::Symbol
    last::L
end

ExternalFunctionUpdate(cf::Function, apply_to::Symbol, env::Entity) = ExternalFunctionUpdate(cf, apply_to, getfield(env, apply_to))

function (e::ExternalFunctionUpdate)(time, env::Entity, effected_updates, args...; kwargs...)
    e.last = e.change_func(time)
    new = e.last + getfield(env, e.apply_to)
    setfield!(env, e.apply_to, new)
    nothing
end

summary(e::ExternalFunctionUpdate) = e.last


