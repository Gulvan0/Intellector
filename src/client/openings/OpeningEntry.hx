package client.openings;

/** An opening's name, the same in every language **/
class OpeningEntry
{
    /** Stable, shared with the server's opening book; saved filters refer to openings by it **/
    public final id:Int;
    /** Empty for the starting position **/
    public final code:String;
    /** Prefixed with the code **/
    public final name:String;

    public function new(id:Int, code:String, name:String)
    {
        this.id = id;
        this.code = code;
        this.name = name;
    }
}
