## Put your tests here.

import cliff
import strutils, sets, options
# import pkg/colors

proc `&=`(sbyte: var seq[byte], schar: seq[char]) =
    sbyte.add(cast[seq[byte]](schar))

# one chunk only
var test_bytes_1: seq[byte]

test_bytes_1 &= @[
    'c', 'l', 'i', '\xFF'
]

test_bytes_1 &= from_int[uint32](32).bytemap(big_endian_n(4))

test_bytes_1 &= @[
    'c', 'l', 'i', '\xFF',
    'c', 'l', 'i', '\xFF',
    't', 'e', 's', 't',
    't', 'e', 's', 't',
    'c', 'l', 'i', 'f', 'f',
    'c', 'l', 'i', 'f', 'f',
    'c', 'l', 'i', 'f', 'f',
    '\0'
]

var test_settings_1 = CliffSettingsV2(
    fields: @[
        static_field(PositionedField(
            field    : Field(
                variant : Variant(kind: vkByteSeq),
                mapping : unit_mapping_n(4),
                inverse : unit_mapping_n(4),
            ),
            from_end : false,
            offset   : 0,
        ), 0),
        static_field(PositionedField(
            field    : Field(
                variant : Variant(kind: vkUInt32),
                mapping : big_endian_n(4),
                inverse : big_endian_n(4),
            ),
            from_end : false,
            offset   : 4,
        ), 1)
    ],
    num_prepend : 2,
    get_id         : proc (fields: seq[Option[Variant]]): seq[byte] = return fields[0].get().val_byte_seq,
    get_lens       : proc (fields: seq[Option[Variant]]): array[3, uint] = return [8, uint(fields[1].get().val_uint_32), 0],
    # get_crc        : ,
)

proc print_byte_line(bytes: openArray[byte]) =
    for b in bytes:
        stdout.write(tohex(b) & " ")
    stdout.write("| ")
    let basic_ascii = PunctuationChars + Letters + Digits
    for b in bytes:
        # if chr(b) == ' ':
        #     stdout.write("sp ")
        # el
        if chr(b) in basic_ascii:
            stdout.write(chr(b) & "  ")
        else:
            # stdout.write(dim("?"))
            stdout.write(tohex(b) & " ")
    echo()

proc print_byte_line(bytes: openArray[byte], num_filled: int) =
    for i in 0..<len(bytes):
        if i < num_filled:
            var b = bytes[i]
            stdout.write(tohex(b) & " ")
        else:
            stdout.write("-- ")
    stdout.write("| ")
    let basic_ascii = PunctuationChars + Letters + Digits
    for i in 0..<len(bytes):
        if i < num_filled:
            var b = bytes[i]
            # if chr(b) == ' ':
            #     stdout.write("sp ")
            # el
            if chr(b) in basic_ascii:
                stdout.write(chr(b) & "  ")
            else:
                # stdout.write(dim("?"))
                stdout.write(tohex(b) & " ")
        else:
            stdout.write("-- ")
    echo()

proc print_bytes(bytes: openArray[byte]) =
    var line_buffer: array[16, byte]
    var j: int
    for i in 0..<len(bytes):
        line_buffer[j] = bytes[i]
        j += 1
        if j >= len(line_buffer):
            print_byte_line(line_buffer)
            j = 0
            line_buffer = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    print_byte_line(line_buffer, j)
    echo(len(bytes))

proc print_bytes(bytes: ByteSection) =
    var line_buffer: array[16, byte]
    var j: int
    for i in 0..<bytes.length:
        line_buffer[j] = bytes.data[i]
        j += 1
        if j >= len(line_buffer):
            print_byte_line(line_buffer)
            j = 0
            line_buffer = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    print_byte_line(line_buffer, j)
    echo(bytes.length)

print_bytes(test_bytes_1)

var data_ptr = cast[ptr UncheckedArray[byte]](alloc0(len(test_bytes_1)))
for i in 0..<len(test_bytes_1):
    data_ptr[i] = test_bytes_1[i]

var chunk: CliffChunkRaw = test_settings_1.parse_chunk(ByteSection(data: data_ptr, length: len(test_bytes_1)))

print_bytes(chunk.prepend)
print_bytes(chunk.data)
print_bytes(chunk.append)

echo(chunk.id)
echo(chunk.lens)
echo(chunk.crc)

echo("-- test 2 --")

var test_settings_2 = CliffSettingsV2(
    fields: @[
        static_field(PositionedField(
            field: Field(
                variant : Variant(kind: vkByteSeq),
                mapping : little_endian_n(6),
                inverse : little_endian_n(6),
            ),
            from_end : false,
            offset   : 0,
        ), 0),
        static_field(PositionedField(
            field: Field(
                variant : Variant(kind: vkUInt16),
                mapping : big_endian_n(2),
                inverse : big_endian_n(2),
            ),
            from_end : false,
            offset   : 6,
        ), 1),
        proc (fields: seq[Option[Variant]]): Option[PositionedField] =
            if fields[1].get().val_uint_16 == 0:
                return some(PositionedField(
                                field: Field(
                                    variant : Variant(kind: vkUInt64),
                                    mapping : big_endian_n(8),
                                    inverse : big_endian_n(8),
                                ),
                                from_end : false,
                                offset   : 8,
                            ))
            else:
                return none(PositionedField)
    ],
    num_prepend : 3,
    get_id   : proc (fields: seq[Option[Variant]]): seq[byte] = return fields[0].get().val_byte_seq,
    get_lens : proc (fields: seq[Option[Variant]]): array[3, uint] =
        if fields[1].get().val_uint_16 == 0:
            return [8, uint(fields[2].get().val_uint_64), 0]
        else:
            return [16, uint(fields[1].get().val_uint_16), 0],
    # get_crc  : ,
    set_id   : proc (id: seq[byte]): seq[(int, Option[Variant])] = return @[(0, some(Variant(kind: vkByteSeq, val_byte_seq: id)))],
    set_lens : proc (data_len: uint): seq[(int, Option[Variant])] =
        if data_len > high(uint16):
            return @[(1, some(Variant(kind: vkUInt16, val_uint16: 0'u16))), (2, some(Variant(kind: vkUInt64, val_uint64: uint64(data_len))))]
        else:
            return @[(1, some(Variant(kind: vkUInt16, val_uint16: uint16(data_len))))],
    set_crc  : proc (crc: seq[byte]): seq[(int, Option[Variant])] = @[(3, none(Variant))],
)

var test2_created_chunk = CliffChunkRaw(
    id   : cast[seq[byte]](@['c', 'l', 'i', 'f', 'f', '2']),
    lens : [8, 256, 0],
    crc  : @[],
)

test_settings_2.update_raw_chunk(test2_created_chunk)

echo("updated raw chunk sections")
print_bytes(test2_created_chunk.prepend)
print_bytes(test2_created_chunk.data)
print_bytes(test2_created_chunk.append)
echo()

echo("write buf len: " & $(test2_created_chunk.lens[0] + test2_created_chunk.lens[1] + test2_created_chunk.lens[2]))
var written_chunk = alloc_bs(test2_created_chunk.lens[0] + test2_created_chunk.lens[1] + test2_created_chunk.lens[2])
echo(written_chunk.length)
echo(written_chunk)

var written_chunk_stepped_along = written_chunk
test2_created_chunk.write_raw_chunk(written_chunk_stepped_along) # write steps for sequential chunk writing
echo(written_chunk.length)
echo(written_chunk)

print_bytes(written_chunk)

var chunk2: CliffChunkRaw = test_settings_2.parse_chunk(written_chunk)

for field in chunk2.all_fields:
    if isSome(field):
        echo(field.get())
    else:
        echo("empty")

assert written_chunk.length == 264

assert isSome(chunk2.all_fields[0])
assert chunk2.all_fields[0].get().val_byte_seq == cast[seq[byte]](@['c', 'l', 'i', 'f', 'f', '2'])

assert isSome(chunk2.all_fields[1])
assert chunk2.all_fields[1].get().val_uint_16 == 256'u16
