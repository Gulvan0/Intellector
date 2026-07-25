package net.models.game;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;
import net.models.game.GameTimeUpdatePublic;
import net.models.common.PieceKind;

class PlyBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var occurred_at:DateTime;
	public var event_index:Int;
	public var ply_index:Int;
	public var from_i:Int;
	public var from_j:Int;
	public var to_i:Int;
	public var to_j:Int;
	@:default(null) public var morph_into:Null<PieceKind>;
	public var sip_after:String;
	@:default(null) public var time_update:Null<GameTimeUpdatePublic>;
}
