package net.shared.dataobj;

class OngoingGameInfo
{
    public var id:Int;
    public var timeData:Null<TimeReservesData>;
    public var currentLog:String;

    public static function create(id:Int, timeData:Null<TimeReservesData>, currentLog:String) 
    {
        var info:OngoingGameInfo = new OngoingGameInfo();
        info.id = id;
        info.timeData = timeData;
        info.currentLog = currentLog;
        return info;
    }

    public function toString():String 
    {
        return 'OngoingGameInfo(ID=$id, $timeData)';
    }

    public function new()
    {
        
    }
}