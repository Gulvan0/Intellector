package net.shared;

class GameInfo
{
    public var id:Int;
    public var log:String;

    public static function create(id:Int, log:String) 
    {
        var info:GameInfo = new GameInfo();
        info.id = id;
        info.log = log;
        return info;
    }

    public function new()
    {
        
    }
}