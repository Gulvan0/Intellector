package net.models.game;

import lib.std.DateTime;
import lib.json.IJsonUnserializableMacro;
import net.models.game.GameTimeUpdatePublic;
import net.models.common.PieceColor;
import net.models.game.OutcomeKind;
import net.models.game.GameEndedEloUpdates;

class GameEndedBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(lib.json.StdParsers.parseDate) public var game_ended_at:DateTime;
	public var kind:OutcomeKind;
	@:default(null) public var winner:Null<PieceColor>;
	@:default(null) public var time_update:Null<GameTimeUpdatePublic>;
	@:default(null) public var elo:Null<GameEndedEloUpdates>;
}
