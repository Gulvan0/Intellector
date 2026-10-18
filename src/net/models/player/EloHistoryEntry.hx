package net.models.player;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;

class EloHistoryEntry implements IJsonUnserializableMacro
{
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var ts:DateTime;
	public var elo:Int;
}
