package net.shared.dataobj;

import net.shared.dataobj.UserStatus;

class MiniProfileData
{
    public var gamesCntByTimeControl:Map<TimeControlType, Int>;
    public var elo:Map<TimeControlType, EloValue>;
    public var status:UserStatus;
    public var isFriend:Bool;

    public function toString():String 
    {
        return 'MiniProfileData {\ngamesCntByTimeControl: $gamesCntByTimeControl\nelo: $elo\nstatus: $status\nisFriend: $isFriend\n}';
    }

    public function new()
    {

    }
}