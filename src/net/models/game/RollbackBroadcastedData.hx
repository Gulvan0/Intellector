package net.models.game;

import lib.std.DateTime;
import lib.json.IJsonUnserializableMacro;
import net.models.game.GameTimeUpdatePublic;
import net.models.common.PieceColor;

class RollbackBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(lib.json.StdParsers.parseDate) public var occurred_at:DateTime;
	public var ply_cnt_before:Int;
	public var ply_cnt_after:Int;
	public var requested_by:PieceColor;
	public var game_id:Int;
	@:default(null) public var time_update:Null<GameTimeUpdatePublic>;
	public var updated_sip:String;
}
