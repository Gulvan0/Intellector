package client.datatypes.games;

/** A page of search results **/
class ArchivePage
{
    public final games:Array<ArchiveGame>;
    /** All the games the search matched **/
    public final total:Int;

    public function new(games:Array<ArchiveGame>, total:Int)
    {
        this.games = games;
        this.total = total;
    }
}
