import std/options
import fields, settings, chunk

proc parse_chunk*(settings: CliffSettingsV2, data: ByteSection): CliffChunkRaw =
    var field_values: seq[Option[Variant]]
    for pf in settings.fields_prepend:
        var maybe_field: Option[PositionedField] = pf(field_values)
        if isSome(maybe_field):
            field_values &= some(data.parse_field(maybe_field.get()))
        else:
            field_values &= none(Variant)
    var id: seq[byte] = settings.get_id(field_values)
    var lens: array[3, uint] = settings.get_lens(field_values)
    return CliffChunkRaw(
        id         : id,
        lens       : lens,
        crc        : @[],
        all_fields : field_values,
        prepend    : data.newlength(int(lens[0])),
        data       : data.newlength(int(lens[1])).slide(int(lens[0])),
        append     : data.newlength(int(lens[2])).slide(int(lens[0] + lens[1])),
    )
