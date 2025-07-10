import std/options
import fields, settings

type
    CliffChunk* {.inheritable.} = object

    CliffChunkRaw* = object of CliffChunk
        id   *: PositionedField
        len1 *: PositionedField
        len2 *: Option[PositionedField]
        ver  *: Option[PositionedField]
        crc  *: Option[PositionedField]

        ## all data for the chunk is copied into one section, prepend then append then data
        ## pointers in each ByteSection are offset within that
        ##
        ## above fields include data extracted by Cliff,
        ## but if additional fields not relevant to cliff are in the prepend or append,
        ## they could be read from here
        prepend *: ByteSection
        append  *: ByteSection
        data    *: ByteSection
