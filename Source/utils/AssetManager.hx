package utils;

import openfl.display.Sprite;
import gfx.components.SpriteWrapper;
import utils.TimeControl.TimeControlType;
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
    public static var timeControlIcons:Map<TimeControlType, SVG>;

    private static inline function piecePath(type:PieceType, color:PieceColor, ?svg:Bool = false):String
    {
        if (svg)
            return "assets/pieces/" + type.getName() + "_" + color.getName() + ".svg";
        else
            return "assets/figures/" + type.getName() + "_" + color.getName().toLowerCase() + ".png";
    }

    private static inline function timeControlPath(type:TimeControlType):String
    {
        var filename = switch type 
        {
            case Hyperbullet: 'bullet';
            case Bullet: 'bullet';
            case Blitz: 'blitz';
            case Rapid: 'rapid';
            case Classic: 'classic';
            case Correspondence: 'correspondence';
        };

        return 'assets/symbols/time_controls/$filename.svg';
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

    public static function getSVGComponent(svg:SVG, x:Float = 0, y:Float = 0, ?width:Int = -1, ?height:Int = -1):SpriteWrapper
    {
        var sprite:Sprite = new Sprite();
        svg.render(sprite.graphics, x, y, width, height);

        var wrapper:SpriteWrapper = new SpriteWrapper();
        wrapper.sprite = sprite;

        return wrapper;
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
                pieceBitmaps[fig][col] = Assets.getBitmapData(piecePath(fig, col));
                pieces[fig][col] = new SVG(Assets.getText(piecePath(fig, col, true)));
            }
        }
    }

    private static function initOther() 
    {
        otherBitmaps = [
            AnalysisMove => Assets.getBitmapData('assets/symbols/move.png'),
            AnalysisDelete => Assets.getBitmapData('assets/symbols/delete.png')
        ];
        timeControlIcons = [for (type in TimeControlType.createAll()) type => new SVG(Assets.getText(timeControlPath(type)))];
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