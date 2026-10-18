package net.models.game;

import net.models.common.PieceColor;
import net.models.game.GameTimeUpdateReason;
import morestd.DateTime;

class GameTimeUpdatePublic
{
	@:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var updated_at:Null<DateTime>;
	public var white_ms:Int;
	public var black_ms:Int;
	@:default(null) public var ticking_side:Null<PieceColor>;
	public var reason:GameTimeUpdateReason;
}
