extcode(v::PackedVector{T}) where {T} = extcode(T)
extcode(::Type{UInt8}) = 0x12
extcode(::Type{Int32}) = 0x15
extcode(::Type{UInt32}) = 0x16
extcode(::Type{Float32}) = 0x17

MsgPack.pack(io::IO, v::PackedVector) = pack(io, MsgPack.Extension(extcode(v),
    convert(Vector{UInt8},
        reshape(reinterpret(UInt8, v.data),
            (sizeof(v.data),)))))
