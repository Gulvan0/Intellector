package net.models.common.mappers;

class HexCoordsMapper
{
    public static function datatypeToDto(datatype:lib.intellectorboard.primitives.hex.HexCoords):net.models.common.HexCoords
    {
        return new net.models.common.HexCoords(datatype.i, datatype.j);
    }

    public static function dtoToDatatype(dto:net.models.common.HexCoords):lib.intellectorboard.primitives.hex.HexCoords
    {
        return new lib.intellectorboard.primitives.hex.HexCoords(dto.i, dto.j);
    }
}
