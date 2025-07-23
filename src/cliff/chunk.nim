import std/options
import fields, settings

type
    CliffChunk* {.inheritable.} = ref object
        id   *: seq[byte]
        lens *: array[3, uint]
        crc  *: seq[byte]
        all_fields *: seq[Option[Variant]]

    CliffChunkRaw* = ref object of CliffChunk
        ## all data for the chunk is copied into one section, prepend then append then data
        ## pointers in each ByteSection are offset within that
        ##
        ## above fields include data extracted by Cliff,
        ## but if additional fields not relevant to cliff are in the prepend or append,
        ## they could be read from here
        prepend *: ByteSection
        data    *: ByteSection
        append  *: ByteSection
