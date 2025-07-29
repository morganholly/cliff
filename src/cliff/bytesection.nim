type
    ByteSection* = object
        data *: ptr UncheckedArray[byte]
        length *: int
        owned_memory *: bool


proc `=destroy`*(bs: ByteSection): void =
    if bs.owned_memory == true and bs.data != nil:
        dealloc(bs.data)

proc `=wasMoved`*(bs: var ByteSection): void =
    if bs.owned_memory == true:
        bs.data = nil

proc `=trace`*(bs: var ByteSection, env: pointer): void =
    discard

proc `=copy`*(bs1: var ByteSection, bs2: ByteSection): void =
    if bs1.data == bs2.data: return
    `=destroy`(bs1)
    `=wasMoved`(bs1)
    bs1.length       = bs2.length
    bs1.owned_memory = true
    if bs2.data != nil:
        if bs2.owned_memory == true:
            bs1.data = cast[ptr UncheckedArray[byte]](alloc0(bs2.length))
            for i in 0..<bs2.length:
                bs1.data[i] = bs2.data[i]
        else:
            bs1.data = bs2.data

proc `=dup`*(bs: ByteSection): ByteSection =
    if bs.data != nil:
        if bs.owned_memory == true:
            result.data = cast[ptr UncheckedArray[byte]](alloc0(bs.length))
            for i in 0..<bs.length:
                result.data[i] = `=dup`(bs.data[i])
        else:
            result.data = bs.data

proc `=sink`*(bs1: var ByteSection, bs2: ByteSection): void =
    `=destroy`(bs1)
    bs1.data         = bs2.data
    bs1.length       = bs2.length
    bs1.owned_memory = bs2.owned_memory


proc alloc_bs*(length: uint): ByteSection =
    return ByteSection(
        data: cast[ptr UncheckedArray[byte]](alloc0(length)),
        length: int(length),
        owned_memory: true
    )


# if not owned_memory, should check bounds and realloc if needed
proc slide*(bs: ByteSection, move: int): ByteSection =
    var new_ptr = cast[uint](bs.data)
    if move >= 0:
        new_ptr += uint(move)
    else:
        new_ptr -= uint(move)
    return ByteSection(data: cast[ptr UncheckedArray[byte]](new_ptr), length: bs.length, owned_memory: false)

proc subset*(bs: ByteSection, move_start_forward, move_end_forward: int): ByteSection =
    var new_ptr = cast[uint](bs.data)
    if move_start_forward >= 0:
        new_ptr += uint(move_start_forward)
    else:
        new_ptr -= uint(move_start_forward)
    return ByteSection(data: cast[ptr UncheckedArray[byte]](new_ptr), length: bs.length + move_end_forward - move_start_forward, owned_memory: false)

proc newlength*(bs: ByteSection, length: int): ByteSection =
    return ByteSection(data: bs.data, length: length, owned_memory: false)


iterator items*(bs: ByteSection): ptr UncheckedArray[byte] =
    var start_ptr = cast[uint](bs.data)
    var i = 0
    while i <= bs.length:
        yield cast[ptr UncheckedArray[byte]](start_ptr + uint(i))
        inc i

proc copy_mem*(dest, source: ByteSection, only_copy_if_all_fits: bool = true): ByteSection {.raises: [RangeDefect].} =
    var fits = dest.length >= source.length
    if only_copy_if_all_fits:
        if fits:
            copy_mem(dest.data, source.data, source.length)
            return ByteSection(data: cast[ptr UncheckedArray[byte]](cast[uint](dest.data) + uint(source.length)), length: dest.length - source.length, owned_memory: dest.owned_memory)
        else:
            raise newException(RangeDefect, "Destination ByteSection has insufficient space for Source ByteSection")
    else:
        var copy_length = min(dest.length, source.length)
        copy_mem(dest.data, source.data, copy_length)
        return ByteSection(data: cast[ptr UncheckedArray[byte]](cast[uint](dest.data) + uint(copy_length)), length: 0)

proc copy_mem*(dest: ptr UncheckedArray[byte], source: ByteSection): ptr UncheckedArray[byte] =
    copy_mem(dest, source.data, source.length)
    return cast[ptr UncheckedArray[byte]](cast[uint](dest) + uint(source.length))
