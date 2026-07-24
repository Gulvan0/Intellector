package net.models.player;

class PlayerGameStatsByTimeControl
{
	@:default(null) public var elo:Null<Int> = null;
	public var is_elo_provisional:Bool;
	public var ranked_games_cnt:Int;
	public var all_games_cnt:Int;
}
