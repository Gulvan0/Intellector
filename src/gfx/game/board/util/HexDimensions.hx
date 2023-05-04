package gfx.game.board.util;

class HexDimensions
{
    public final sideLength:Float;
    public final width:Float;
    public final height:Float;

    public static function sideToWidth(sideLength:Float):Float
    {
        return sideLength * 2;
    }

    public static function sideToHeight(sideLength:Float):Float
    {
        return sideLength * Math.sqrt(3);
    }

    public static function widthToSide(w:Float):Float
    {
        return w / 2;
    }

    public static function heightToSide(h:Float):Float
    {
        return h / Math.sqrt(3);
    }

    public function new(sideLength:Float) 
    {
        this.sideLength = sideLength;
        this.width = sideToWidth(sideLength);
        this.height = sideToHeight(sideLength);
    }
}