package engine.hxconda.board;

enum abstract PlayerColor(Int) to Int
{
    var White = 0;
    var Black = 1;

    public inline function opponent():PlayerColor
    {
        return cast (this ^ 1);
    }
}
