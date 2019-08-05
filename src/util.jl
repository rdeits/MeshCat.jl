# TODO: Base PR
@inline function mergesorted!(dest::AbstractVector, a, b; by=identity, lt=isless)
    i = 1
    it_a = iterate(a)
    it_b = iterate(b)
    while it_a !== nothing
        val_a, state_a = it_a
        if it_b === nothing
            dest[i += 1] = val_a
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
        dest[i += 1] = val_b
        copyto!(dest, i, Iterators.rest(b, state_b))
    end
    return dest
end
