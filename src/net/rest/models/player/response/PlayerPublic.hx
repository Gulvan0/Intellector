package net.rest.models.player.response;

import net.rest.models.player.submodels.GameStats;
import lib.stdtypes.DateTime;
import net.rest.models.player.submodels.PlayerRestrictionPublic;
import net.rest.models.player.submodels.PlayerRolePublic;
import net.rest.models.common.TimeControlKind;
import net.rest.models.player.submodels.UserStatus;
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
