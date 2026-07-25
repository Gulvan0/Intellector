package net.models.game;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;
import net.models.game.GameTimeUpdatePublic;
import net.models.common.PieceColor;

class TimeAddedBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var occurred_at:DateTime;
	public var event_index:Int;
	public var amount_seconds:Int;
	public var receiver:PieceColor;
	public var time_update:GameTimeUpdatePublic;
}
