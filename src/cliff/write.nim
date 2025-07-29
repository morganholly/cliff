import std/options
import fields, settings, chunk

proc write_raw_chunk*(chunk: CliffChunkRaw, write_ptr: var ByteSection) =
    ## only writes `CliffChunkRaw` `ByteSection`s, if `CliffChunk` fields are updated, use `update_raw`
    write_ptr = write_ptr.copy_mem(chunk.prepend)
    write_ptr = write_ptr.copy_mem(chunk.data)
    write_ptr = write_ptr.copy_mem(chunk.append)
