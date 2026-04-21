package net.models.player;

class GameStats
{
	@:default(null) public var elo:Null<Int> = null;
	public var is_elo_provisional:Bool;
	public var games_cnt:Int;
}
