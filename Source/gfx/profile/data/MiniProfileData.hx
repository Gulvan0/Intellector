package gfx.profile.data;

import net.shared.UserRole;
import net.shared.TimeControlType;
import net.shared.EloValue;

class MiniProfileData
{
    public var gamesCntByTimeControl:Map<TimeControlType, Int>;
    public var elo:Map<TimeControlType, EloValue>;
    public var status:UserStatus;
    public var isFriend:Bool;

    public function new()
    {

    }
}