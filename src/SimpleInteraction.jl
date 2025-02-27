"""
apply_what and record_what have to have time as their first input, and the same args as their other inputs.
"""

abstract type AbstractUpdate end
abstract type AbstractRecorder end

"""
    RecordedUpdate(update_function, times_to_update, times_to_record, record_function, name::Symbol)
"""
struct RecordedUpdate{F<:Function,S,T,N<:Function} <: AbstractUpdate
    apply_what::F
    times_to_update::S
    times_to_record::T
    record_what::N
    name::Symbol
end

mutable struct SimpleRecorder{S} <: AbstractRecorder
    summary::Vector{S}
    ru::RecordedUpdate
end

SimpleRecorder(ru::RecordedUpdate, T::DataType) = SimpleRecorder(
    Vector{T}(undef,length(ru.times_to_record)),
    ru
)

SimpleRecorder(ru::RecordedUpdate) = SimpleRecorder(ru, Any)

name(s::SimpleRecorder) = s.ru.name

recording_times(s::SimpleRecorder) = s.ru.times_to_record
recording_function(s::SimpleRecorder) = s.ru.record_what


function scratch(r::SimpleRecorder, position::Integer, time, args...)
    r.summary[position] = recording_function(r)(time, args...) |> deepcopy
end

times_to_update(ru::RecordedUpdate, position::Number) = @view ru.times_to_update[position:end]
times_to_record(ru::RecordedUpdate, position::Number) = @view ru.times_to_record[position:end]

function i_should_update(time::Number, ru::RecordedUpdate, position::Number)
    return time ∈ times_to_update(ru, position)
end

function i_should_record(time::Number, ru::RecordedUpdate, position::Number)
    return time ∈ times_to_record(ru, position)
end



function (ru::RecordedUpdate)(; data_type::DataType = Any)
    recorder = SimpleRecorder(ru,data_type)
    recorder_position = 1
    updater_position = 1
    function update!(time, args...)
        if i_should_update(time, ru, updater_position)
            ru.apply_what(time, args...)
            updater_position+=1
        end

        if i_should_record(time, ru, recorder_position)
            scratch(recorder, recorder_position, time, args...)
            recorder_position+=1
        end
    end

    return update!, recorder
end


struct CompositeRecord{S<:AbstractRecorder} 
    records::Vector{S}
end

(c::CompositeRecord)(_name::Symbol) = c.records[findfirst(c.records) do rec
        name(rec) == _name
    end]

function Base.getindex(c::CompositeRecord, i::Integer)
    return c.records[i]  # Access the underlying array and return the indexed element
end

function (s::SimpleRecorder)(t::Integer)
    indx = findfirst(isequal(t), recording_times(s))
    isnothing(indx) && error("no record at that time!")
    return s.summary[indx]
end

function (s::SimpleRecorder)(r::AbstractRange)
    indices = findall(x -> x in r, recording_times(s))
    return s.summary[indices]
end






function compose_updates(updates, types::Vector{D}) where D<:DataType 
    all = map(zip(updates, types)) do (ru, type)
        ru(;data_type=type) 
    end
    updates = first.(all)
    recorders=last.(all)

    function composite_update!(time,args...)
        for upd in updates
            upd(time, args...)
        end
    end
    return composite_update!, CompositeRecord(recorders)
end

function compose_updates(updates)
    t = repeat([Any], length(updates))
    compose_updates(updates, t)
end


function Base.show(io::IO, ::MIME"text/plain", r::SimpleRecorder)
    times = recording_times(r)
    if length(times) == 0
        print("Empty record of $(name(r))")
    elseif length(times) == 1
        print("Records of $(name(r))  at time $(times)")
    else
        print("Records of $(name(r))  at times $(times[1]) to $(times[end]), probably stepsize $(times[2] - times[1])")
    end
end

function Base.show(io::IO, r::SimpleRecorder)
    times = recording_times(r)
    if length(times) == 0
        print("Empty record of $(name(r))")
    elseif length(times) == 1
        print("Records of $(name(r))  at time $(times)")
    else
        print("Records of $(name(r))  at times $(times[1]) to $(times[end]), probably stepsize $(times[2] - times[1])")
    end
end


function Base.show(io::IO, ::MIME"text/plain", c::CompositeRecord)
    for (i, r) in enumerate(c.records)
        print("Index [$i] : ")
        Base.show(r)
        println("")
    end
end


