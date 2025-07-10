import std/options
import fields

type
    CSFieldOrderElement* {.size:sizeof(byte).} = enum
        order_ID   = 0, ## - identifier of the chunk type
        order_VER  = 1, ## - version of the chunk type. can be useful for files which are themselves one chunk, that starts with a file wide version
        order_LEN1 = 2, ## - length 1 of data
        order_LEN2 = 3, ## - override length of data
        order_PAL  = 4, ## - calculates lengths of prepend and append
        order_field_len = 5

    CliffSettings* = object
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
        field_id   *: proc (fields: seq[Option[Field]], pal: Option[int]): PositionedField
        field_ver  *: proc (fields: seq[Option[Field]], pal: Option[int]): Option[PositionedField]
        field_len1 *: proc (fields: seq[Option[Field]], pal: Option[int]): PositionedField
        field_len2 *: proc (fields: seq[Option[Field]], pal: Option[int]): Option[PositionedField]
        prepend_append_lengths *: proc (fields: seq[Option[Field]]): (int, int)
        ## always determined last
        field_crc  *: proc (fields: seq[Option[Field]], pal: Option[int]): Option[PositionedField]
        crc_after  *: proc (fields: seq[Option[Field]], pal: Option[int]): bool
