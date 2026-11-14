package client.datatypes.games;

/** A filter saved on the server **/
class SavedFilter
{
    public final id:Int;
    /** An authorless filter's link key, null for the users' filters **/
    public final key:Null<String>;
    public final name:String;
    /** Null for an authorless filter **/
    public final authorLogin:Null<String>;
    /** Null for an authorless filter **/
    public final authorNickname:Null<String>;
    /** In the stored formula format, as JSON **/
    public final formulaJson:String;

    public function new(id:Int, key:Null<String>, name:String, authorLogin:Null<String>, authorNickname:Null<String>, formulaJson:String)
    {
        this.id = id;
        this.key = key;
        this.name = name;
        this.authorLogin = authorLogin;
        this.authorNickname = authorNickname;
        this.formulaJson = formulaJson;
    }
}
