package net.models.game;

import jsonmodel.IJsonUnserializableMacro;
import net.models.game.GameEvent;
import net.models.game.GameOutcomePublic;
import net.models.game.GameTimeUpdatePublic;
import net.models.game.GameStateRefreshReason;

class GameStateRefresh implements IJsonUnserializableMacro
{
	public var refresh_reason:GameStateRefreshReason;
	@:default(null) public var outcome:Null<GameOutcomePublic>;
	@:jcustomparse(net.models.game.SpecialParsers.parseGenericEventList) public var events:Array<GameEvent>;
	@:default(null) public var latest_time_update:Null<GameTimeUpdatePublic>;
}
