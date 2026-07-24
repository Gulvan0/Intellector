package net.models.common.mappers;

class TimeControlMapper
{
    public static function datatypeToDto(datatype:client.datatypes.TimeControl):Null<net.models.common.FischerTimeControl>
    {
        return switch datatype {
            case None: null;
            case Fischer(instance): FischerTimeControlMapper.datatypeToDto(instance);
        }
    }

    public static function dtoToDatatype(dto:Null<net.models.common.FischerTimeControl>):client.datatypes.TimeControl
    {
        if (dto == null)
            return None;
        return Fischer(FischerTimeControlMapper.dtoToDatatype(dto));
    }
}
