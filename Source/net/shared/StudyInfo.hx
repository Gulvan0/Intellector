package net.shared;

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
        return 'StudyInfo {\n name: $name\n description: $description\n tags:$tags\n publicity:$publicity\n keyPositionSIP:$keyPositionSIP\n variantStr:$variantStr\n}';
    }

    public function new()
    {

    }
}