package net.models.player;

import jsonmodel.IJsonUnserializableMacro;
import net.models.game.OngoingGamePublic;

class PlayerOngoingGamesStateRefresh implements IJsonUnserializableMacro
{
	public var current_games:Array<OngoingGamePublic>;
}
