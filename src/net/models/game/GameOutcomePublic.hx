package net.models.game;

import net.models.common.PieceColor;
import net.models.game.OutcomeKind;
import net.models.game.GameTimeUpdatePublic;
import lib.std.DateTime;

class GameOutcomePublic
{
	@:jcustomparse(lib.json.StdParsers.parseDate) public var game_ended_at:DateTime;
	public var kind:OutcomeKind;
	@:default(null) public var winner:Null<PieceColor>;
	@:default(null) public var time_update:Null<GameTimeUpdatePublic>;
}
