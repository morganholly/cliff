import std/options
import fields

type
    CliffSettings* = object
        ## remaps the following list to set field processing order
        ## [
        ## ID   - identifier of the chunk type
        ## VER  - version of the chunk type. can be useful for files which are themselves one chunk, that starts with a file wide version
        ## LEN1 - length 1 of data
        ## LEN2 - override length of data
        ## ]
        field_order *: ByteMapping

        ## fields, containing values and types, are passed in in `field_order` order, as the values are parsed
        ## the first proc gets no input, second gets one, third gets two, and fourth gets three
        ## crc gets all values
        ##
        ## once `prepend_append_lengths` is called
        ## all following procs will recieve a value for either the prepend (first three) or append (crc)
        field_id   *: proc (spf: seq[PositionedField], pal: Option[int]): PositionedField
        field_ver  *: proc (spf: seq[PositionedField], pal: Option[int]): PositionedField
        use_ver    *: proc (spf: seq[PositionedField], pal: Option[int]): bool
        field_len1 *: proc (spf: seq[PositionedField], pal: Option[int]): PositionedField
        field_len2 *: proc (spf: seq[PositionedField], pal: Option[int]): PositionedField
        use_len2   *: proc (spf: seq[PositionedField], pal: Option[int]): bool
        prepend_append_lengths *: proc (spf: seq[PositionedField]): (int, int)
        ## always determined last
        field_crc  *: proc (spf: seq[PositionedField], pal: Option[int]): PositionedField
        use_crc    *: proc (spf: seq[PositionedField], pal: Option[int]): bool
        crc_after  *: proc (spf: seq[PositionedField], pal: Option[int]): bool
