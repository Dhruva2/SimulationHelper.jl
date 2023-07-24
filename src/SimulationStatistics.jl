"""
These functions are convenient for plotting simulation hyperparameters / repeats against statistics (e.g. learning performance.)

They all assume a simulation function of the form:

f(hyperparameters::Dict) = _, _, records

where records is something from which all useful statistics can be taken with functions.

Statistics type functions take a simulation function, and output a function of the form:
    range, outs = statistic(simulation::Function, hyperparameters)


"""

"""
    x -> f(x, ...) over range
    f should return two outputs. of which the last is outputs over one repeat.
"""
function do_repeats(statistic::Function, range, num_repeats)
    outputs = map(1:num_repeats) do i
        map(range) do r
            _, output = statistic(r)
            return output
        end
    end
    return range, outputs
end


"""
The final arguments should be functions that take the overall vector of records, and provide the specific record required
"""
function param_against_difference(f::Function, hypers::Dict, pname::Symbol, prange, record1::Function, record2::Function)
    diffs = map(prange) do r
        hypers[pname] = r
        _, _, records = f(hypers)
        return difference(record1(records), record2(records))
    end
    return prange, diffs
end

function param_against_summary(f::Function, hypers, pname::Symbol, prange, extract_summary::Function)
    diffs = map(prange) do r
        hypers[pname] = r
        _, _, records = f(hypers)
        return extract_summary(records)
    end
    return prange, diffs
end

function param_against_summary_repeated(f::Function, hypers, pname::Symbol, prange, extract_summary::Function, repeats::Integer)

    stat(x) = param_against_summary(f, hypers, pname, x, extract_summary)
    return do_repeats(stat, prange, repeats)
end

"""
    param_against_mse(hyperparameters, :num_particles, 1:1:20) |> plot
"""
param_against_mse(f::Function, hypers::Dict, pname::Symbol, prange) = param_against_summary(
    f,
    hypers,
    pname,
    prange,
    x -> x[:collection](CumulativeSquaredError).summary[end]
)