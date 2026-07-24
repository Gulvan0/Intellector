package net.models.game;

import lib.json.IJsonUnserializableMacro;
import net.models.game.GamePublic;

class CurrentGameListStateRefresh implements IJsonUnserializableMacro
{
	public var games:Array<GamePublic>;
}
