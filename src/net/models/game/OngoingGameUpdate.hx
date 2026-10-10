package net.models.game;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;
import net.models.game.GameTimeUpdatePublic;

class OngoingGameUpdate implements IJsonUnserializableMacro
{
	public var game_id:Int;
	public var ply_cnt:Int;
	public var latest_sip:String;
	@:default(null) @:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var last_ply_at:Null<DateTime>;
	@:default(null) public var latest_time_update:Null<GameTimeUpdatePublic>;
}
