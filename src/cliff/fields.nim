import std/options
# import std/strutils


type
    ByteMapping* = object
        # size*: int
        # mapping*: ptr UncheckedArray[int]
        mapping*: seq[int]
        correct*: bool # true if all numbers `0..<len(mapping)` are present

converter array_to_bytemapping*(arr: seq[int]): ByteMapping =
    var check: seq[bool] = newSeq[bool](len(arr))
    result = ByteMapping(
        # size: len(arr),
        # mapping: cast[ptr UncheckedArray[int]](alloc0(len(arr) * sizeof(int))),
        mapping: newSeq[int](len(arr)),
        correct: false
    )
    for i in 0 ..< len(arr):
        var clamped = max(min(arr[i], len(arr) - 1), 0)
        result.mapping[i] = clamped
        check[clamped] = true
    var missing: bool
    for i in 0 ..< len(arr):
        missing = missing or (not check[i])
    result.correct = not missing

proc bytemap*(data: openArray[byte], bm: ByteMapping): seq[byte]=
    for i in 0..<min(len(data), len(bm.mapping)):
        result &= data[bm.mapping[i]]

proc bytemap*(data: ptr UncheckedArray[byte], bm: ByteMapping): seq[byte]=
    for i in 0..<len(bm.mapping):
        result &= data[bm.mapping[i]]

proc make_inverse*(bm: ByteMapping): Option[ByteMapping] =
    if not bm.correct:
        return none(ByteMapping)
    else:
        var out_map = newSeq[int](len(bm.mapping))
        for i in 0..<len(bm.mapping):
            block innerloop:
                for j in 0..<len(bm.mapping):
                    if bm.mapping[j] == i:
                        out_map[i] = j
                        break innerloop
        return some(array_to_bytemapping(out_map))

proc to_int*[T: SomeInteger](data: openArray[byte]): T =
    assert len(data) >= sizeof(T)
    var n = min(len(data), 8)
    for i in 0..<n:
        # result = result or (cast[uint64](data[i]) shl ((n - i - 1) * 8))
        result = result or (cast[T](data[i]) shl (i * 8))
    return cast[T](result)

proc to_int*[T: SomeInteger](data: ptr UncheckedArray[byte], length: int): T =
    assert length >= sizeof(T)
    var n = min(length, 8)
    for i in 0..<n:
        # result = result or (cast[uint64](data[i]) shl ((n - i - 1) * 8))
        result = result or (cast[T](data[i]) shl (i * 8))
    return cast[T](result)

proc from_int*[T: SomeInteger](integer: T): seq[byte] =
    var integer64: uint64 = cast[uint64](integer)
    var n = min(sizeof(T), 8)
    for i in 0..<n:
        # result[i] = cast[byte]((integer64 shr ((n - i - 1) * 8)) and 0xFF)
        result &= cast[byte]((integer64 shr (i * 8)) and 0xFF)

proc write_int*[T: SomeInteger](integer: T, data: ptr UncheckedArray[byte]): void =
    var integer64: uint64 = cast[uint64](integer)
    var n = min(sizeof(T), 8)
    for i in 0..<n:
        # result[i] = cast[byte]((integer64 shr ((n - i - 1) * 8)) and 0xFF)
        data[i] = cast[byte]((integer64 shr (i * 8)) and 0xFF)

block:
    # echo(toHex(0x12345678'u64))
    # echo(0x12345678'u64)
    # echo(from_int[uint64](0x12345678'u64))
    # echo(to_int[uint64](from_int[uint64](0x12345678'u64)))
    # echo(toHex(to_int[uint64](from_int[uint64](0x12345678'u64))))

    # echo(toHex(0x12345678'u32))
    # echo(0x12345678'u32)
    # echo(from_int[uint32](0x12345678'u32))
    # echo(to_int[uint32](from_int[uint32](0x12345678'u32)))
    # echo(toHex(to_int[uint32](from_int[uint32](0x12345678'u32))))

    # echo(toHex(0x1234'u32))
    # echo(0x1234'u32)
    # echo(from_int[uint32](0x1234'u32))
    # echo(to_int[uint32](from_int[uint32](0x1234'u32)))
    # echo(toHex(to_int[uint32](from_int[uint32](0x1234'u32))))

    # echo(toHex(0xA3'u8))
    # echo(0xA3'u8)
    # echo(from_int[uint8](0xA3'u8))
    # echo(to_int[uint8](from_int[uint8](0xA3'u8)))
    # echo(toHex(to_int[uint8](from_int[uint8](0xA3'u8))))

    # # var bmtest: ByteMapping = @[4, 5, 6, 7, 0, 1, 2, 3]
    # var bmtest: ByteMapping = @[1, 0, 3, 2, 5, 4, 7, 6]

    # echo(toHex(0x12345678'u64))
    # echo(0x12345678'u64)
    # echo(from_int[uint64](0x12345678'u64))
    # echo(from_int[uint64](0x12345678'u64).bytemap(bmtest))
    # echo(to_int[uint64](from_int[uint64](0x12345678'u64).bytemap(bmtest)))
    # echo(toHex(to_int[uint64](from_int[uint64](0x12345678'u64).bytemap(bmtest))))
    discard

type
    FieldKind* = enum
        fkBool,
        fkInt8,
        fkInt16,
        fkInt32,
        fkInt64,
        # higher bit sizes not implemented yet
        fkUInt8,
        fkUInt16,
        fkUInt32,
        fkUInt64,
        # higher bit sizes not implemented yet
        fkFloat32,
        fkFloat64,
        fkChar4,
        fkByteSeq

    Field* = object
        mapping *: ByteMapping
        inverse *: ByteMapping
        case kind *: FieldKind:
            of fkBool:
                val_bool *: bool
            of fkInt8:    val_int_8    *: int8
            of fkInt16:   val_int_16   *: int16
            of fkInt32:   val_int_32   *: int32
            of fkInt64:   val_int_64   *: int64
            of fkUInt8:   val_uint_8   *: uint8
            of fkUInt16:  val_uint_16  *: uint16
            of fkUInt32:  val_uint_32  *: uint32
            of fkUInt64:  val_uint_64  *: uint64
            of fkFloat32: val_float_32 *: float32
            of fkFloat64: val_float_64 *: float64
            of fkChar4:   val_char_4   *: array[4, char]
            of fkByteSeq: val_byte_seq *: seq[byte]
        # one file might store 0x00 for false and 0x01 for true
        # while another *could* store 0x00-0x7E for false and 0x7F-0xFF for true
        # which would offer increased resistance to corruption
        # this means conversion varies between formats
        bool_from_byte *: proc (read_byte: byte): bool = proc (x: byte): bool = return x > 0x00
        bool_to_byte   *: proc (write_bool: bool): byte = proc (y: bool): byte = (if y: return 0x01 else: return 0x00)

proc parse_field*(data: openArray[byte], field: Field): Field =
    # input is not modified since it will be read from settings object
    result = Field(
        mapping: field.mapping,
        inverse: field.inverse,
        kind: field.kind
    )
    let remapped = bytemap(data, field.mapping)
    case field.kind:
        of fkBool:    result.val_bool     = field.bool_from_byte(remapped[0])
        of fkInt8:    result.val_int_8    = cast[int8](remapped[0])
        of fkInt16:   result.val_int_16   = to_int[int16](remapped)
        of fkInt32:   result.val_int_32   = to_int[int32](remapped)
        of fkInt64:   result.val_int_64   = to_int[int64](remapped)
        of fkUInt8:   result.val_uint_8   = remapped[0]
        of fkUInt16:  result.val_uint_16  = to_int[uint16](remapped)
        of fkUInt32:  result.val_uint_32  = to_int[uint32](remapped)
        of fkUInt64:  result.val_uint_64  = to_int[uint64](remapped)
        of fkFloat32: result.val_float_32 = cast[float32](to_int[uint32](remapped))
        of fkFloat64: result.val_float_64 = cast[float64](to_int[uint64](remapped))
        of fkChar4:   result.val_char_4   = [cast[char](remapped[0]), cast[char](remapped[1]), cast[char](remapped[2]), cast[char](remapped[3])]
        of fkByteSeq: result.val_byte_seq = @remapped
    # case field.kind:
    #     of fkBool, fkInt8, fkUInt8:               result.length = 1
    #     of fkInt16, fkUInt16:                     result.length = 2
    #     of fkInt32, fkUInt32, fkFloat32, fkChar4: result.length = 4
    #     of fkInt64, fkUInt64, fkFloat64:          result.length = 8
    #     of fkByteSeq:                             result.length = len(remapped)
    result.bool_from_byte = field.bool_from_byte
    result.bool_to_byte   = field.bool_to_byte

proc parse_field*(data: ptr UncheckedArray[byte], field: Field): Field =
    # input is not modified since it will be read from settings object
    result = Field(
        mapping: field.mapping,
        inverse: field.inverse,
        kind: field.kind
    )
    let remapped = bytemap(data, field.mapping)
    case field.kind:
        of fkBool:    result.val_bool     = field.bool_from_byte(remapped[0])
        of fkInt8:    result.val_int_8    = cast[int8](remapped[0])
        of fkInt16:   result.val_int_16   = to_int[int16](remapped)
        of fkInt32:   result.val_int_32   = to_int[int32](remapped)
        of fkInt64:   result.val_int_64   = to_int[int64](remapped)
        of fkUInt8:   result.val_uint_8   = remapped[0]
        of fkUInt16:  result.val_uint_16  = to_int[uint16](remapped)
        of fkUInt32:  result.val_uint_32  = to_int[uint32](remapped)
        of fkUInt64:  result.val_uint_64  = to_int[uint64](remapped)
        of fkFloat32: result.val_float_32 = cast[float32](to_int[uint32](remapped))
        of fkFloat64: result.val_float_64 = cast[float64](to_int[uint64](remapped))
        of fkChar4:   result.val_char_4   = [cast[char](remapped[0]), cast[char](remapped[1]), cast[char](remapped[2]), cast[char](remapped[3])]
        of fkByteSeq: result.val_byte_seq = @remapped
    result.bool_from_byte = field.bool_from_byte
    result.bool_to_byte   = field.bool_to_byte

proc field_to_bytes*(field: Field): seq[byte] =
    var unremapped: seq[byte]
    case field.kind:
        of fkBool:    unremapped &= field.bool_to_byte(field.val_bool)
        of fkInt8:    unremapped &= cast[byte](field.val_int_8)
        of fkInt16:   unremapped  = from_int[int16](field.val_int_16)
        of fkInt32:   unremapped  = from_int[int32](field.val_int_32)
        of fkInt64:   unremapped  = from_int[int64](field.val_int_64)
        of fkUInt8:   unremapped &= cast[byte](field.val_uint_8)
        of fkUInt16:  unremapped  = from_int[uint16](field.val_uint_16)
        of fkUInt32:  unremapped  = from_int[uint32](field.val_uint_32)
        of fkUInt64:  unremapped  = from_int[uint64](field.val_uint_64)
        of fkFloat32: unremapped  = from_int[uint32](cast[uint32](field.val_uint_32))
        of fkFloat64: unremapped  = from_int[uint64](cast[uint64](field.val_uint_64))
        of fkChar4:   unremapped  = @[cast[byte](field.val_char_4[0]), cast[byte](field.val_char_4[1]), cast[byte](field.val_char_4[2]), cast[byte](field.val_char_4[3])]
        of fkByteSeq: unremapped  = field.val_byte_seq
    return bytemap(unremapped, field.inverse)

proc write_field*(data: ptr UncheckedArray[byte], field: Field): void =
    let bytes = field_to_bytes(field)
    for i in 0..<len(bytes):
        data[i] = bytes[i]

type
    ByteSection* = object
        data *: ptr UncheckedArray[byte]
        length *: int

    PositionedField* = object
        field *: Field
        ## false will position field from start of data length, true will position from end
        from_end *: bool
        ## shifts forward when `from_end` is false, shifts back when `from_end` is true
        ## if `from_end`, length of `field` is accounted for using length of field.mapping.mapping
        ## always in bytes
        offset *: int

proc parse_field*(section: ByteSection, pf: PositionedField): Field =
    let offset: int = if pf.from_end:
                            section.length - (pf.offset + len(pf.field.mapping.mapping))
                        else:
                            pf.offset
    return parse_field(cast[ptr UncheckedArray[byte]](cast[uint](section.data) + uint(offset)), pf.field)

proc write_field*(section: ByteSection, pf: PositionedField): void =
    let offset: int = if pf.from_end:
                            section.length - (pf.offset + len(pf.field.mapping.mapping))
                        else:
                            pf.offset
    write_field(cast[ptr UncheckedArray[byte]](cast[uint](section.data) + uint(offset)), pf.field)
