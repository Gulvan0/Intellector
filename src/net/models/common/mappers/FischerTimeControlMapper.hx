package net.models.common.mappers;

class FischerTimeControlMapper
{
    public static function datatypeToDto(datatype:client.datatypes.FischerTimeControl):net.models.common.FischerTimeControl
    {
        return new net.models.common.FischerTimeControl(datatype.startSeconds, datatype.incrementSeconds);
    }

    public static function dtoToDatatype(dto:net.models.common.FischerTimeControl):client.datatypes.FischerTimeControl
    {
        return new client.datatypes.FischerTimeControl(dto.start_seconds, dto.increment_seconds);
    }
}
