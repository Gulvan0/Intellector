package;

import gfx.components.analysis.PosEditMode;
import openfl.Assets;
import openfl.display.BitmapData;
import struct.PieceType;
import struct.PieceColor;

enum AssetName
{
    AnalysisMove;
    AnalysisDelete;
}

class AssetManager 
{
    public static var pieceBitmaps:Map<PieceType, Map<PieceColor, BitmapData>>;
    public static var otherBitmaps:Map<AssetName, BitmapData>;

    public static inline function pathToImage(type:PieceType, color:PieceColor, ?icon:Bool = false):String
    {
        var filename:String = type.getName() + "_" + color.getName().toLowerCase();
        if (icon)
            return 'assets/figicons/$filename.png';
        else
            return 'assets/figures/$filename.png';
    }

    public static function getAnalysisPosEditorBtnIcon(mode:PosEditMode):BitmapData
    {
        return switch mode 
        {
            case Move: otherBitmaps[AnalysisMove];
            case Delete: otherBitmaps[AnalysisDelete];
            case Set(type, color): pieceBitmaps[type][color];
        }
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

    private static function initOther() 
    {
        otherBitmaps = [
            AnalysisMove => Assets.getBitmapData('assets/symbols/move.png'),
            AnalysisDelete => Assets.getBitmapData('assets/symbols/delete.png')
        ];    
    }
}