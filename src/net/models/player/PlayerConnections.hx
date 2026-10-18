package net.models.player;

import jsonmodel.IJsonUnserializableMacro;

class PlayerConnections implements IJsonUnserializableMacro
{
	public var friends:Array<PlayerCard>;
	public var following:Array<PlayerCard>;
	public var followers:Array<PlayerCard>;
}
