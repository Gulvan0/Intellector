package net.models.player;

import jsonmodel.IJsonUnserializableMacro;

class PlayerSearchResult implements IJsonUnserializableMacro
{
	public var players:Array<PlayerSearchEntry>;
	public var total_count:Int;
}
