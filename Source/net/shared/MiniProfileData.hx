package net.shared;

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