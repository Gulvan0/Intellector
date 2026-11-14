package client.datatypes.games;

/** One level of the result table's sorting **/
class SortLevel
{
    public final column:ResultColumn;
    public final descending:Bool;

    public function new(column:ResultColumn, descending:Bool)
    {
        this.column = column;
        this.descending = descending;
    }
}
