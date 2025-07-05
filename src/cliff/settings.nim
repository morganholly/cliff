import math, strutils


type
    ByteMapping* = object
        size*: int
        mapping*: ptr UncheckedArray[int]
        correct*: bool # true if all numbers are present

converter array_to_bytemapping*(arr: seq[int]): ByteMapping =
    var check: seq[bool] = newSeq[bool](len(arr))
    result = ByteMapping(
        size: len(arr),
        mapping: cast[ptr UncheckedArray[int]](alloc0(len(arr) * sizeof(int))),
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
    for i in 0..<min(len(data), bm.size):
        result &= data[bm.mapping[i]]

proc bytemap*(data: ptr UncheckedArray[byte], bm: ByteMapping): seq[byte]=
    for i in 0..<bm.size:
        result &= data[bm.mapping[i]]

proc to_int*[T: SomeInteger](data: openArray[byte]): T =
    assert len(data) >= sizeof(T)
    var n = min(len(data), 8)
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

# block:
#     echo(toHex(0x12345678'u64))
#     echo(0x12345678'u64)
#     echo(from_int[uint64](0x12345678'u64))
#     echo(to_int[uint64](from_int[uint64](0x12345678'u64)))
#     echo(toHex(to_int[uint64](from_int[uint64](0x12345678'u64))))

#     echo(toHex(0x12345678'u32))
#     echo(0x12345678'u32)
#     echo(from_int[uint32](0x12345678'u32))
#     echo(to_int[uint32](from_int[uint32](0x12345678'u32)))
#     echo(toHex(to_int[uint32](from_int[uint32](0x12345678'u32))))

#     echo(toHex(0x1234'u32))
#     echo(0x1234'u32)
#     echo(from_int[uint32](0x1234'u32))
#     echo(to_int[uint32](from_int[uint32](0x1234'u32)))
#     echo(toHex(to_int[uint32](from_int[uint32](0x1234'u32))))

#     echo(toHex(0xA3'u8))
#     echo(0xA3'u8)
#     echo(from_int[uint8](0xA3'u8))
#     echo(to_int[uint8](from_int[uint8](0xA3'u8)))
#     echo(toHex(to_int[uint8](from_int[uint8](0xA3'u8))))

#     # var bmtest: ByteMapping = @[4, 5, 6, 7, 0, 1, 2, 3]
#     var bmtest: ByteMapping = @[1, 0, 3, 2, 5, 4, 7, 6]

#     echo(toHex(0x12345678'u64))
#     echo(0x12345678'u64)
#     echo(from_int[uint64](0x12345678'u64))
#     echo(from_int[uint64](0x12345678'u64).bytemap(bmtest))
#     echo(to_int[uint64](from_int[uint64](0x12345678'u64).bytemap(bmtest)))
#     echo(toHex(to_int[uint64](from_int[uint64](0x12345678'u64).bytemap(bmtest))))

