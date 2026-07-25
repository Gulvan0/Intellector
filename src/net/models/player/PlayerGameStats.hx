package net.models.player;

import jsonmodel.IJsonUnserializableMacro;
import net.models.common.TimeControlKind;

class PlayerGameStats implements IJsonUnserializableMacro
{
    public var by_time_control:Map<TimeControlKind, PlayerGameStatsByTimeControl>;
    @:default(null) public var best_ranked:Null<TimeControlKind>;
    public var total_count:Int;
}
