package net.models.player;

import net.models.player.GameStats;
import lib.std.DateTime;
import net.models.player.PlayerRestrictionPublic;
import net.models.player.PlayerRolePublic;
import net.models.common.TimeControlKind;
import net.models.player.UserStatus;
import lib.json.IJsonUnserializableMacro;

class PlayerPublic implements IJsonUnserializableMacro
{
	public var login:String;
	@:jcustomparse(lib.json.StdParsers.parseDate) public var joined_at:DateTime;
	public var nickname:String;
	public var is_friend:Bool;
	public var status:UserStatus;
	public var per_time_control_stats:Map<TimeControlKind, GameStats>;
	public var total_stats:GameStats;
	public var studies_cnt:Int;
	public var roles:Array<PlayerRolePublic>;
	public var restrictions:Array<PlayerRestrictionPublic>;
}
