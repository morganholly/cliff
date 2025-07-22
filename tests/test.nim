## Put your tests here.

import cliff
import strutils, sets
# import pkg/colors

proc `&=`(sbyte: var seq[byte], schar: seq[char]) =
    sbyte.add(cast[seq[byte]](schar))

# one chunk only
var test_bytes_1: seq[byte]

test_bytes_1 &= @[
    'c', 'l', 'i', '\xFF'
]

test_bytes_1 &= from_int[uint32](32)

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
    fields_prepend : @[
        static_field(PositionedField(
            field    : Field(
                variant : Variant(kind: vkByteSeq),
                mapping : unit_mapping_n(4),
                inverse : unit_mapping_n(4),
            ),
            from_end : false,
            offset   : 0,
        )),
        static_field(PositionedField(
            field    : Field(
                variant : Variant(kind: vkUInt32),
                mapping : unit_mapping_n(4),
                inverse : unit_mapping_n(4),
            ),
            from_end : false,
            offset   : 4,
        ))
    ],
    get_id         : proc (fields: seq[Option[Variant]]): seq[byte] = return fields[0].get().val_byte_seq,
    get_lens       : proc (fields: seq[Option[Variant]]): array[3, uint] = return [8, uint(fields[1].get().val_uint_32), 0],
    fields_append  : @[],
    # get_crc        : ,
)

proc print_byte_line(bytes: openArray[byte]) =
    for b in bytes:
        stdout.write(tohex(b) & " ")
    stdout.write("| ")
    for b in bytes:
        # if chr(b) == ' ':
        #     stdout.write("sp ")
        # el
        if chr(b) in PrintableChars:
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
    for i in 0..<len(bytes):
        if i < num_filled:
            var b = bytes[i]
            # if chr(b) == ' ':
            #     stdout.write("sp ")
            # el
            if chr(b) in PrintableChars:
                stdout.write(chr(b) & "  ")
            else:
                # stdout.write(dim("?"))
                stdout.write(tohex(b) & " ")
        else:
            stdout.write("-- ")
    echo()

proc print_bytes(bytes: openArray[byte])=
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
    echo()
    echo(len(bytes))

print_bytes(test_bytes_1)