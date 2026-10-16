package net.models.study.mappers;

import intellectorboard.primitives.ply.RawPly;
import net.models.common.mappers.HexCoordsMapper;
import net.models.common.mappers.PieceKindMapper;

class ApiPlyMapper
{
    public static function toDto(ply:RawPly):ApiPly
    {
        var morphInto:Null<net.models.common.PieceKind> = ply.morphInto != null ? PieceKindMapper.datatypeToDto(ply.morphInto) : null;
        return new ApiPly(HexCoordsMapper.datatypeToDto(ply.from), HexCoordsMapper.datatypeToDto(ply.to), morphInto);
    }
}
