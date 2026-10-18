package net.models.game;

import net.models.common.PieceColor;
import net.models.game.OutcomeKind;
import net.models.game.GameTimeUpdatePublic;
import morestd.DateTime;

class GameOutcomePublic
{
	@:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var game_ended_at:Null<DateTime>;
	public var kind:OutcomeKind;
	@:default(null) public var winner:Null<PieceColor>;
	@:default(null) public var time_update:Null<GameTimeUpdatePublic>;
	@:optional @:default(null) public var white_elo_delta:Null<Int>;
	@:optional @:default(null) public var black_elo_delta:Null<Int>;
}
