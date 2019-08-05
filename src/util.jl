# Port of possible implementation of std::merge (second version),
# https://en.cppreference.com/w/cpp/algorithm/merge
# TODO: contribute to base.

"""
    mergesorted!(dest::AbstractVector, a, b; by=identity, lt=isless)

Merge sorted iterators `a` and `b`, storing the result in `dest`.
`dest` should be of the appropriate length to store all elements of `a` and `b`;
it is not resized.

For equivalent elements in `a` and `b`, the elements from `a`
(preserving their original order) precede the elements from `b`
(preserving their original order).

Elements are compared by `(x, y) -> lt(by(x), by(y))`

The behavior is undefined if `dest` overlaps `a` or `b` (though the `a` and `b`
may overlap each other) or if `a` or `b` are not sorted.

Adapted from https://en.cppreference.com/w/cpp/algorithm/merge.
"""
@inline function mergesorted!(dest::AbstractVector, a, b; by=identity, lt=isless)
    i = 1
    it_a = iterate(a)
    it_b = iterate(b)
    while it_a !== nothing
        val_a, state_a = it_a
        if it_b === nothing
            dest[i] = val_a
            i += 1
            copyto!(dest, i, Iterators.rest(a, state_a))
            return dest
        end
        val_b, state_b = it_b
        if lt(by(val_b), by(val_a))
            dest[i] = val_b
            it_b = iterate(b, state_b)
        else
            dest[i] = val_a
            it_a = iterate(a, state_a)
        end
        i += 1
    end
    if it_b !== nothing
        val_b, state_b = it_b
        dest[i] = val_b
        i += 1
        copyto!(dest, i, Iterators.rest(b, state_b))
    end
    return dest
end

# from https://github.com/JuliaOpt/MathOptInterface.jl/blob/d3106f434293a2aae7c664a22a30a7bd4069111a/src/Utilities/functions.jl#L390.
# TODO: contribute to Base
function combine!(x::AbstractVector; by=identity, keep=x->true, combine)
    @boundscheck issorted(x; by=by) || throw(ArgumentError("Input is not sorted."))
    if length(x) > 0
        i1 = firstindex(x)
        for i2 in eachindex(x)[2:end]
            if by(x[i1]) == by(x[i2])
                x[i1] = combine(x[i1], x[i2])
            else
                if !keep(x[i1])
                    x[i1] = x[i2]
                else
                    x[i1 + 1] = x[i2]
                    i1 += 1
                end
            end
        end
        if !keep(x[i1])
            i1 -= 1
        end
        resize!(x, i1)
    end
    return x
end
