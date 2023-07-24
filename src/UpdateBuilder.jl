"""
The important functions here are the functors for (i::InteractionSpecification) and (e::entity)(...).
The secondary function is `augment`, to sort and build prerequisites for an interaction specification
The other functions are just for use in augment or the functors.
"""






"""
    - make a recorder for the entity itself: erec
    - make an augmented, sorted, vector of interaction specifications
    - 
"""
function (e::Entity)(updatespecs::Vector{T}) where {T<:Specification}
    sorted = augment(updatespecs) #add unspecified interaction dependencies
    urs = map(updatespecs) do i
        i() # pair: updates and recorders for each interaction spec
    end
    updates = first.(urs)
    recorders = last.(urs)
    function composite_update(time, args...; kwargs...)
        for (i, upd) in updates |> enumerate
            upd(time, e, sorted[1:i], args...; kwargs...)
        end
    end
    return composite_update, recorders
end



function find_interaction(effected_updates, update_type)
    indx = findfirst(x -> typeof(x.of_what) <: update_type, effected_updates)
    return effected_updates[indx]
end



"""
Functions necessary for augmenting and sorting an interaction specification if it relies on subinteractions that are undeclared, or has to go in an order relative to other interactions
"""


"""
    augment(is_vec)
This function takes a vector of interaction specifications. It produces a new vector, including all necessary requirements, and reordered so nth interaction specification depends on the previous n-1 interaction specifications
"""
function augment(is_vec::Vector{T}) where {T<:Specification}
    trim!(is_vec)
    sorted = is_vec[requirements.(is_vec).|>isempty]
    to_sort = is_vec[requirements.(is_vec).|>!isempty]

    while !isempty(to_sort)
        to_sort_cache = empty(to_sort)
        delete_cache = empty([1])
        for (i, is) in enumerate(to_sort)
            for (j, el) in requirements(is) |> enumerate
                if isroot(el, sorted)
                    maybe_add!(sorted, el, is)
                else
                    push!(to_sort_cache, el)
                end
            end
            if isroot(is::Specification, sorted)
                maybe_add!(sorted, is)
                push!(delete_cache, i)
            end
        end
        deleteat!(to_sort, delete_cache)
        cat(to_sort, to_sort_cache, dims=1)
        trim!(to_sort)
        trim!(sorted)
    end
    return sorted
end

function maybe_add!(vec::Vector{Specification}, el::Thing, parent_spec::InteractionSpecification)
    which_indx = empty([1])
    to_merge = empty(vec)
    for (i, v) in enumerate(vec)
        if v.of_what == el
            merged = merger(vec[i], el, parent_spec)
            push!(to_merge, merged)
            push!(which_indx, i)
        end
    end
    push!(vec, to_merge...)
    if isempty(which_indx)
        elspec = InteractionSpecification(
            el,
            parent_spec.times_to_update,
            parent_spec.times_to_record,
            () -> ()
        )
        push!(vec, elspec)
    end

    deleteat!(vec, which_indx)
end



function maybe_add!(vec::Vector{T}, el::Specification) where {T<:Specification}

    which_indx = empty([1])
    for (i, v) in enumerate(vec)
        if v.of_what == el.of_what
            merged = merger(vec[i], el)
            push!(vec, merged)
        end
    end
    deleteat!(vec, which_indx)
end

function sortedvecmerge(v1, v2)
    return vcat(v1, v2) |> unique |> sort
end


# function merge(i::InteractionSpecification, i2::InteractionSpecification)
#     return InteractionSpecification(
#         i.of_what,
#         sortedvecmerge(i.times_to_update, i2.times_to_update),
#         sortedvecmerge(i.times_to_record, i2.times_to_record),
#         i.record_what
#     )
# end

# function merge(i::ObservationSpecification, i2::ObservationSpecification)
#     return ObservationSpecification(
#         i.of_what,
#         sortedvecmerge(i.times_to_record, i2.times_to_record),
#         i.record_what
#     )
# end

function merger(i::InteractionSpecification, i2::Thing, parent::InteractionSpecification)
    (i.of_what !== i2) && error("incompatible merge")
    return InteractionSpecification(
        i.of_what,
        sortedvecmerge(i.times_to_update, parent.times_to_update),
        sortedvecmerge(i.times_to_record, parent.times_to_record),
        i.record_what
    )
end


"""
Is it a root node in the requirements tree: either no requirements, or all requirements are already 
"""
function isroot(el::Thing, is_vec::Vector{T}) where {T<:Specification}
    interactions = map(x -> x.of_what, is_vec)
    map(requirements(el)) do r
        r ∈ interactions
    end |> all
end
isroot(s::Specification, is_vec) = isroot(s.of_what, is_vec)

"""
Delete all duplicated interactions. Merge their potentially non-identical but overlapping times_to_update and times_to_record
"""
function trim!(is_vec::Vector{T}) where {T<:Specification}
    delete_cache = empty([1])
    for (i, v) in enumerate(is_vec)
        if v ∈ is_vec[1:i-1]
            maybe_add!(is_vec[1:i-1], v)
            push!(delete_cache, i)
        end
    end
    deleteat!(is_vec, delete_cache)
end