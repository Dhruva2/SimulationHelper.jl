
mutable struct Recorder{T,S,I<:Thing,A} <: AbstractRecorder
    times::T
    summary::S
    of_what::I
    record_what::A
end


function Base.show(io::IO, ::MIME"text/plain", r::Recorder)
    if length(r.times) == 0
        print("Empty record of $(name(r))")
    elseif length(r.times) == 1
        print("Records of $(name(r))  at time $(r.times[1])")
    else
        print("Records of $(name(r))  at times $(r.times[1]) to $(r.times[end])), probably stepsize $(r.times[2] - r.times[1])")
    end
end

function Base.show(io::IO, r::Recorder)
    if length(r.times) == 0
        print("Empty record of $(name(r))")
    else
        print("Records of $(name(r))  at times $(r.times[1]) to $(r.times[end]))")
    end
end

function Base.show(io::IO, ::MIME"text/plain", recorders::Vector{T}) where {T<:Recorder}
    for (i, r) in enumerate(recorders)
        print("Index [$i] : ")
        Base.show(r)
        println("")
    end
end


name(r::Recorder) = Symbol(Symbol(r.record_what), :_of_, name(r.of_what))

Recorder(is::Specification) = Recorder(
    is.times_to_record,
    Vector{typeof(is.record_what(is.of_what))}(undef, length(is.times_to_record)),
    is.of_what,
    is.record_what
)

# Recorder(is::InteractionSpecification, field::Symbol) = Recorder(is, rec -> getfield(rec, field))




(r::Recorder)(position) = r.summary[position]

function scratch(r::Recorder, position::Integer)
    r.summary[position] = deepcopy(r.record_what(r.of_what))
end


"""
Functionality for composite records: vectors of records
"""
# function (v::Vector{T})(s::Symbol) where {T<:Recorder}
#     indx = findfirst(v) do r
#         s == name(r)
#     end
#     println("at position $indx")
#     return v[indx]
# end

function get_record(r::Recorder, t)
    indx = findfirst(isequal(t), r.times)
    isnothing(indx) && error("no record at that time!")
    r.summary[indx]
end

# function find_record(records::Vector{T}, record_what) where {T<:Recorder}
#     indx = findfirst(x -> x.record_what == record_what, records)
#     return records[indx]
# end

function (records::Vector{T})(s::Function) where {T<:Union{Recorder,Specification}}
    indx = findfirst(x -> x.record_what == s, records)
    return records[indx]
end


function (records::Vector{T})(type_name) where {T<:Union{Recorder,Specification}}
    indx = findfirst(x -> typeof(x.of_what) <: type_name, records)
    return records[indx]
end

function (records::Vector{T})(s::Function, type_name) where {T<:Union{Recorder,Specification}}
    function isit(x)
        (typeof(x.of_what) <: type_name) && (x.record_what == s)
    end
    indx = findfirst(isit, records)
    if isnothing(indx)
        @warn "couldn't find requested record"
        return nothing
    else
        return records[indx]
    end
end

function difference(r1::Recorder, r2::Recorder)
    return sum(abs2, r2.summary - r1.summary)
end


