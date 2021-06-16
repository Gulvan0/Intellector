package;

import openfl.Assets;
import openfl.display.BitmapData;
import struct.PieceType;
import struct.PieceColor;

class AssetManager 
{
    public static var pieceBitmaps:Map<PieceType, Map<PieceColor, BitmapData>>;

    public static inline function pathToImage(type:PieceType, color:PieceColor, ?icon:Bool = false):String
    {
        var filename:String = type.getName() + "_" + color.getName().toLowerCase();
        if (icon)
            return 'assets/figicons/$filename.png';
        else
            return 'assets/figures/$filename.png';
    }

    public static function init() 
    {
        initPieces();
    }

    private static function initPieces()
    {
        pieceBitmaps = [];
        for (fig in PieceType.createAll())
        {
            pieceBitmaps[fig] = new Map<PieceColor, BitmapData>();
            for (col in PieceColor.createAll())
                pieceBitmaps[fig][col] = Assets.getBitmapData(pathToImage(fig, col));
        }
    }
}