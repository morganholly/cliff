import std/options
import fields

type
    CSFieldOrderElement* {.size:sizeof(byte).} = enum
        order_ID   , ## - identifier of the chunk type
        order_VER  , ## - version of the chunk type. can be useful for files which are themselves one chunk, that starts with a file wide version
        order_LEN1 , ## - length 1 of data
        order_LEN2 , ## - override length of data
        order_PAL  , ## - calculates lengths of prepend and append
        order_OTHER,
        order_field_len

    CliffSettingsV1* = object
        ## sets field processing order
        ## ordering must start with ID, LEN1, or VER
        field_order *: array[order_field_len, CSFieldOrderElement]

        ## fields, containing values and types, are passed in in `field_order` order, as the values are parsed
        ## the first proc gets no input, second gets one, third gets two, and fourth gets three
        ## crc gets all values
        ## if a field is not returned by a preceeding proc, it will be `none()` in `fields`
        ##
        ## once `prepend_append_lengths` is called
        ## all following procs will recieve a value for either the prepend (first three) or append (crc)
        field_id   *: proc (fields: seq[Option[Variant]], pal: Option[int]): PositionedField
        field_ver  *: proc (fields: seq[Option[Variant]], pal: Option[int]): Option[PositionedField]
        field_len1 *: proc (fields: seq[Option[Variant]], pal: Option[int]): PositionedField
        field_len2 *: proc (fields: seq[Option[Variant]], pal: Option[int]): Option[PositionedField]
        prepend_append_lengths *: proc (fields: seq[Option[Variant]]): (int, int)
        ## always determined last
        field_crc  *: proc (fields: seq[Option[Variant]], pal: Option[int]): Option[PositionedField]
        crc_after  *: proc (fields: seq[Option[Variant]], pal: Option[int]): bool
        fields_other *: seq[proc (fields: seq[Option[Variant]]): Option[PositionedField]]

        ## readlen = ((len * scale1) + offset) * scale2
        data_len_scale1 *: int
        data_len_offset *: int
        data_len_scale2 *: int

proc static_field*(pf: PositionedField): proc (fields: seq[Option[Variant]]): Option[PositionedField] =
    return proc (fields: seq[Option[Variant]]): Option[PositionedField] = return some(pf)

type
    CliffSettingsV2* = object
        fields_prepend *: seq[proc (fields: seq[Option[Variant]]): Option[PositionedField]]
        get_id   *: proc (fields: seq[Option[Variant]]): seq[byte]
        get_lens *: proc (fields: seq[Option[Variant]]): array[3, uint] # prepend, data, append
        fields_append *: seq[proc (fields: seq[Option[Variant]]): Option[PositionedField]]
        get_crc  *: proc (fields: seq[Option[Variant]]): seq[byte]
