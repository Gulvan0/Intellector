package net.models.game;

import jsonmodel.IJsonUnserializableMacro;

class GameSearchResult implements IJsonUnserializableMacro
{
	public var games:Array<GameSummaryPublic>;
	public var total:Int;
	@:default(null) public var counts:Null<GameSearchCounts>;
}
