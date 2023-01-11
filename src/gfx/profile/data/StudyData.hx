package gfx.profile.data;

import net.shared.dataobj.StudyInfo;

class StudyData
{
    public final id:Int;
    public final ownerLogin:String;
    public final info:StudyInfo;

    public function new(id:Int, ownerLogin:String, info:StudyInfo) 
    {
        this.id = id;
        this.ownerLogin = ownerLogin;
        this.info = info;
    }
}