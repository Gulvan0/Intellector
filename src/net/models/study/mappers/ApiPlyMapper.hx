package net.models.study.mappers;

import net.models.common.mappers.PieceKindMapper;
import intellectorboard.primitives.ply.RawPly;
import net.models.common.mappers.HexCoordsMapper;

class ApiPlyMapper
{
    public static function toDto(ply:RawPly):ApiPly
    {
        return new ApiPly(HexCoordsMapper.datatypeToDto(ply.from), HexCoordsMapper.datatypeToDto(ply.to), PieceKindMapper.datatypeToDto(ply.morphInto));
    }
}
