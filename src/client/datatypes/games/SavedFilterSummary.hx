package client.datatypes.games;

/** A user's saved filter, as their list of filters names it **/
class SavedFilterSummary
{
    public final id:Int;
    public final name:String;

    public function new(id:Int, name:String)
    {
        this.id = id;
        this.name = name;
    }
}
