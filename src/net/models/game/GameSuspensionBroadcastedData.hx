package net.models.game;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;
import net.models.game.GameTimeUpdatePublic;

class GameSuspensionBroadcastedData implements IJsonUnserializableMacro
{
    public var event_index:Int;
    public var suspended:Bool;
    @:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var last_seen_at:Null<DateTime>;
    @:default(null) public var time_update:Null<GameTimeUpdatePublic>;
}
