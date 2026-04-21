package net.models.game;

import net.models.common.PieceColor;
import net.models.game.GameTimeUpdateReason;
import lib.std.DateTime;

class GameTimeUpdatePublic
{
	@:jcustomparse(lib.json.StdParsers.parseDate) public var updated_at:DateTime;
	public var white_ms:Int;
	public var black_ms:Int;
	@:default(null) public var ticking_side:Null<PieceColor>;
	public var reason:GameTimeUpdateReason;
}
