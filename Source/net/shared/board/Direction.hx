package net.shared.board;

enum InternalDirection
{
    Up;
    UpLeft;
    UpRight;
    Down;
    DownLeft;
    DownRight;
    AgrUpLeft;
    AgrUpRight;
    AgrDownLeft;
    AgrDownRight;
    AgrLeft;
    AgrRight;
}

abstract Direction(InternalDirection) from InternalDirection to InternalDirection
{
    public static function allLateral():Array<InternalDirection>
    {
        return [Up, UpLeft, UpRight, Down, DownLeft, DownRight];
    }

    public static function allRadial():Array<InternalDirection>
    {
        return [AgrUpLeft, AgrUpRight, AgrDownLeft, AgrDownRight, AgrLeft, AgrRight];
    }

    public static function forwardLateral(color:PieceColor):Array<InternalDirection>
    {
        return color == White? [Up, UpLeft, UpRight] : [Down, DownLeft, DownRight];
    }
}