"""
Shorthand for information on when to use an interaction to update its environment, and when to record it
How to record it is in recorder.jl
"""


struct InteractionSpecification{I<:Interaction,S,T,N<:Function} <: Specification
    of_what::I
    times_to_update::S
    times_to_record::T
    record_what::N
end


struct ObservationSpecification{I<:Thing,T,N<:Function} <: Specification
    of_what::I
    times_to_record::T
    record_what::N
end
ObservationSpecification(i::Interaction, times, what) = InteractionSpecification(i, empty(times), times, what)

Record(t::Thing, times, what) = ObservationSpecification(t, times, what)

### IE if you don't want to record, use the pair syntax
Base.Pair(i::Interaction, t) = InteractionSpecification(i, t, empty(t), summary) #update don't record
Base.Pair(e::Entity, t) = ObservationSpecification(e, t, summary)

Record(os::ObservationSpecification, what) = ObservationSpecification(
    os.of_what,
    os.times_to_record,
    what
)

####### Mainly for an is that has been initialised as a pair, and you now want to add times_to_record
Record(is::InteractionSpecification, t, what::Function) = InteractionSpecification(
    is.of_what,
    is.times_to_update,
    t,
    what
)
Record(is::InteractionSpecification, t) = Record(is, t, summary)
Record(is::InteractionSpecification, t, what::Symbol) = Record(is, t, r -> getfield(r, what))

Record(is::InteractionSpecification, what::Function) = InteractionSpecification(
    is.of_what,
    is.times_to_update,
    is.times_to_update,
    what
)
Record(is::InteractionSpecification) = Record(is, summary)
#######

# Record(e::Entity, times, what) = InteractionSpecification()


"""
requirement calculus

"""
requirements(s::Specification) = requirements(s.of_what)
requirements(i::Interaction) = ()
requirements(t::Thing) = ()

my_time(is::InteractionSpecification) = time(is.of_what)
my_time(i::Interaction) = i.time

"""
nb this == is a bit misleading, but useful for subsequent code. Interaction Specifications are equal if they contain the same component interaction, even if they specify different timepoints to record/update the interaction. In the latter case, the code ensures they are anyway merged into a single interaction
"""
==(i1::Specification, i2::Specification) = (==(i1.of_what, i2.of_what)) && ==(i1.record_what, i2.record_what)


summary(i::Interaction) = i




"""
    - make a recorder for the interaction
    - make an update function that updates the entity at the appropriate times, and the recorder at teh appropriate times.
    - interaction itself needs to be a functor: int(entity, effected_updates, time)
"""
function i_should_update(time::Number, i::Specification, position::Number)
    return time ∈ times_to_update(i, position)
end
times_to_update(i::InteractionSpecification, position::Number) = @view i.times_to_update[position:end]
times_to_update(o::ObservationSpecification, position::Number) = 0:0

function i_should_record(time::Number, i::Specification, position::Number)
    return time ∈ times_to_record(i, position)
end
times_to_record(i::Specification, position::Number) = @view i.times_to_record[position:end]


function (i::Specification)()
    recorder = Recorder(i)
    int = i.of_what
    recorder_position = 1
    updater_position = 1
    function update!(time, args...; kwargs...)
        if i_should_update(time, i, updater_position)
            int(time, args...; kwargs...)
            updater_position += 1
        end

        if i_should_record(time, i, recorder_position)
            scratch(recorder, recorder_position)
            # recorder(recorder_position)
            recorder_position += 1
        end
    end
    return update!, recorder
end





