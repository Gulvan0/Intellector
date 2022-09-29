package tests.data;

import net.shared.StudyInfo;

class StudyInfos
{
    public static function tagList1():Array<String>
    {
        return ["test1", "разобрать потом", "flank_attack"];
    }
    
    public static function tag(i:Int)
    {
        return tagList1()[i];
    }

    public static function info1():StudyInfo
    {
        var info:StudyInfo = new StudyInfo();

		info.name = "Some clever name";
		info.description = "This study is about bla-bla-bla and bla-bla-bla, moreover, bla-bla-bla. Some more bla-bla-bla and bla-bla-bla and bla-bla-bla";
		info.publicity = Public;
		info.tags = tagList1();
		info.variantStr = "";
        info.keyPositionSIP = "w\\rerlrvn!DnZr";

        return info;
    }
}