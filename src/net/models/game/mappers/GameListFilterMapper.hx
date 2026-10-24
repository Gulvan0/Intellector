package net.models.game.mappers;

import client.datatypes.game.GameListFilter;
import net.models.common.TimeControlKind;
import net.models.common.mappers.TimeControlKindMapper;
import net.ws.channels.RecentGameList;

class GameListFilterMapper
{
    public static function filterToRecentChannel(filter:GameListFilter):RecentGameList
    {
        var kinds:Array<TimeControlKind> = (filter.queriedKinds() ?? []).map(TimeControlKindMapper.datatypeToDto);
        kinds.sort((a, b) -> Reflect.compare((a : String), (b : String)));
        return new RecentGameList(kinds, filter.rated);
    }
}
