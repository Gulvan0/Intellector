package net.models.game.mappers;

import client.datatypes.game.GameClock;
import intellectorboard.primitives.piece.PieceColor;
import net.models.common.mappers.PieceColorMapper;

class GameClockMapper
{
    public static function dtoToDatatype(dto:Null<GameTimeUpdatePublic>):Null<GameClock>
    {
        if (dto == null)
            return null;

        var tickingSide:Null<PieceColor> = dto.ticking_side != null ? PieceColorMapper.dtoToDatatype(dto.ticking_side) : null;
        return new GameClock(dto.white_ms, dto.black_ms, tickingSide, dto.updated_at != null ? dto.updated_at.getUnixMs() : null);
    }
}
