package net.models.player;

import jsonmodel.IJsonUnserializableMacro;
import net.models.game.GamePublic;

class StartedPlayerGamesStateRefresh implements IJsonUnserializableMacro
{
	public var current_games:Array<GamePublic>;
}
