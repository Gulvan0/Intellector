package net.rest.models.game.submodels;

import net.rest.models.common.PieceColor;
import lib.stdtypes.DateTime;

class GameOutcomePublic
{
	@:jcustomparse(lib.json.StdParsers.parseDate) public var game_ended_at:DateTime;
	public var kind:OutcomeKind;
	@:default(null) public var winner:Null<PieceColor>;
	@:default(null) public var time_update:Null<GameTimeUpdatePublic>;
}
