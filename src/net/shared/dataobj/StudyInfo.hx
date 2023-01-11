package net.shared.dataobj;

class StudyInfo
{
    public var name:String;
    public var description:String;
    public var tags:Array<String>;
    public var publicity:StudyPublicity;
    public var keyPositionSIP:String;
    public var variantStr:String;

    public function toString():String 
    {
        return 'StudyInfo(Name=$name)';
    }

    public function new()
    {

    }
}