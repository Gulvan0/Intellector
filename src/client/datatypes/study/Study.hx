package client.datatypes.study;

/** A saved study, its moves aside **/
class Study
{
    public final id:Int;
    public final authorLogin:String;
    public final authorNickname:String;
    public final createdAtMs:Float;
    public final modifiedAtMs:Float;
    public final details:StudyDetails;

    public function new(id:Int, authorLogin:String, authorNickname:String, createdAtMs:Float, modifiedAtMs:Float, details:StudyDetails)
    {
        this.id = id;
        this.authorLogin = authorLogin;
        this.authorNickname = authorNickname;
        this.createdAtMs = createdAtMs;
        this.modifiedAtMs = modifiedAtMs;
        this.details = details;
    }
}
