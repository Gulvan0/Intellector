package utils;

import format.SVG;
import gfx.analysis.PosEditMode;
import openfl.geom.Matrix;
import struct.Ply;
import struct.Situation;
import struct.Hex;
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
    public static var pieces:Map<PieceType, Map<PieceColor, SVG>>; //new
    public static var pieceBitmaps:Map<PieceType, Map<PieceColor, BitmapData>>; //deprecated
    public static var otherBitmaps:Map<AssetName, BitmapData>;

    private static inline function pathToImage(type:PieceType, color:PieceColor, ?svg:Bool = false):String
    {
        if (svg)
            return "assets/pieces/" + type.getName() + "_" + color.getName() + ".svg";
        else
            return "assets/figures/" + type.getName() + "_" + color.getName().toLowerCase() + ".png";
    }

    public static function playPlySound(ply:Ply, situation:Situation)
    {
        var isCastle:Bool = Rules.isCastle(ply, situation);
        var isNotCapture:Bool = situation.get(ply.to).isEmpty() || isCastle;

        if (isNotCapture)
            Assets.getSound("sounds/move.mp3").play();
        else 
            Assets.getSound("sounds/capture.mp3").play();
    }

    public static function getAnalysisPosEditorBtnIcon(mode:PosEditMode):BitmapData
    {
        switch mode 
        {
            case Move: 
                return otherBitmaps[AnalysisMove];
            case Delete: 
                return otherBitmaps[AnalysisDelete];
            case Set(type, color): 
                return pieceBitmaps[type][color];
        }
    }

    public static function init() 
    {
        initPieces();
        initOther();
    }

    private static function initPieces()
    {
        pieces = [];
        pieceBitmaps = [];
        for (fig in PieceType.createAll())
        {
            pieces[fig] = new Map<PieceColor, SVG>();
            pieceBitmaps[fig] = new Map<PieceColor, BitmapData>();
            for (col in PieceColor.createAll())
            {
                pieceBitmaps[fig][col] = Assets.getBitmapData(pathToImage(fig, col));
                pieces[fig][col] = new SVG(Assets.getText(pathToImage(fig, col, true)));
            }
        }
    }

    private static function initOther() 
    {
        otherBitmaps = [
            AnalysisMove => Assets.getBitmapData('assets/symbols/move.png'),
            AnalysisDelete => Assets.getBitmapData('assets/symbols/delete.png')
        ];    
    }

    private static function scaleBitmapData(bitmapData:BitmapData, scale:Float):BitmapData 
    {
        scale = Math.abs(scale);
        var width:Int = Math.round(bitmapData.width * scale);
        var height:Int = Math.round(bitmapData.height * scale);
        var transparent:Bool = bitmapData.transparent;
        var result:BitmapData = new BitmapData(width, height, transparent);
        var matrix:Matrix = new Matrix();
        matrix.scale(scale, scale);
        result.draw(bitmapData, matrix);
        return result;
    }
}