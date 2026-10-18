package net.models.game.mappers;

import client.datatypes.game.GameCounts;
import client.datatypes.timecontrol.TimeControlKind;
import net.models.common.mappers.TimeControlKindMapper;

class GameCountsMapper
{
    public static function dtoToDatatype(dto:GameSearchCounts):GameCounts
    {
        var byKind:Map<TimeControlKind, Int> = [];
        for (kind => count in dto.time_control_kinds)
            byKind.set(TimeControlKindMapper.dtoToDatatype(kind), count);
        return new GameCounts(byKind, dto.rated.rated, dto.rated.casual);
    }
}
