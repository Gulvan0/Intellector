package net.models.game;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;
import net.models.game.GameTimeUpdatePublic;
import net.models.common.PieceColor;

class RollbackBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var occurred_at:DateTime;
	public var event_index:Int;
	public var ply_cnt_before:Int;
	public var ply_cnt_after:Int;
	public var requested_by:PieceColor;
	@:default(null) public var time_update:Null<GameTimeUpdatePublic>;
	public var updated_sip:String;
}
