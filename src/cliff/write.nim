import std/options
import fields, settings, chunk

proc setmem_chunk*(chunk: var CliffChunkRaw, bs_all: ByteSection) {.raises: [RangeDefect].} =
    if bs_all.length < int(chunk.lens[0] + chunk.lens[1] + chunk.lens[2]):
        raise newException(RangeDefect, "Input ByteSection has insufficient space for chunk")
    else:
        chunk.prepend = newlength(bs_all, int(chunk.lens[0]))
        chunk.data    = newlength(bs_all, int(chunk.lens[1])).slide(int(chunk.lens[0]))
        chunk.append  = newlength(bs_all, int(chunk.lens[2])).slide(int(chunk.lens[0] + chunk.lens[1]))

proc allocate_chunk*(chunk: var CliffChunkRaw) =
    setmem_chunk(chunk, alloc_bs(chunk.lens[0] + chunk.lens[1] + chunk.lens[2]))

proc update_raw_chunk*(settings: CliffSettingsV2, chunk: var CliffChunkRaw) =
    var  id_variant: seq[(int, Option[Variant])] = settings.set_id  (chunk.id)
    var len_variant: seq[(int, Option[Variant])] = settings.set_lens(chunk.lens[1])
    var crc_variant: seq[(int, Option[Variant])] = settings.set_crc (chunk.crc)

    var max_idx: int
    for j in @[id_variant, len_variant, crc_variant]:
        for i in j:
            if max_idx < i[0]:
                max_idx = i[0]
    if len(chunk.all_fields) <= max_idx:
        chunk.all_fields.setLen(max_idx + 1)

    for j in @[id_variant, len_variant, crc_variant]:
        for i in j:
            chunk.all_fields[i[0]] = i[1]

    let has_mem = [
        chunk.prepend.data != nil,
        chunk.data.data != nil,
        chunk.append.data != nil
    ]

    if has_mem == [false, false, false]:
        allocate_chunk(chunk)
    elif has_mem != [true, true, true]:
        # loop and check and allocate individually
        discard

    for i in 0..<min(len(chunk.all_fields), len(settings.fields)):
        var opt_pf = settings.fields[i](chunk.all_fields[0..i])
        if isSome(opt_pf):
            if i < settings.num_prepend:
                chunk.prepend.write_field(opt_pf.get())
            else:
                chunk.append.write_field(opt_pf.get())

proc write_raw_chunk*(chunk: CliffChunkRaw, write_ptr: var ByteSection) =
    ## only writes `CliffChunkRaw` `ByteSection`s, if `CliffChunk` fields are updated, use `update_raw_chunk`
    write_ptr = write_ptr.copy_mem(chunk.prepend)
    write_ptr = write_ptr.copy_mem(chunk.data)
    write_ptr = write_ptr.copy_mem(chunk.append)
