package client.datatypes;

/**
    A request to change which ply of a game's history is shown.
**/
enum PlyNavigationType
{
    Start;
    Previous;
    Next;
    End;
    // The position after the ply at `index` (0-based); -1 for the starting position.
    AfterPly(index:Int);
}
