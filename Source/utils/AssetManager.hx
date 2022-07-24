package utils;

import haxe.CallStack;
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

class AssetManager 
{
    public static var pieces:Map<PieceType, Map<PieceColor, SVG>> = [];
    public static var timeControlIcons:Map<TimeControlType, SVG> = [];

    private static var loadedResourcesCnt:Int = 0;
    private static var totalResourcesCnt:Int = PieceType.createAll().length * PieceColor.createAll().length + TimeControlType.createAll().length;
    private static var onLoadedCallback:Void->Void;

    public static inline function piecePath(type:PieceType, color:PieceColor):String
    {
        return "assets/pieces/" + type.getName() + "_" + color.getName() + ".svg";
    }

    public static inline function editModeIconPath(mode:PosEditMode):String
    {
        return switch mode {
            case Move: "assets/symbols/analysis/move.svg";
            case Delete: "assets/symbols/analysis/delete.svg";
            case Set(type, color): piecePath(type, color);
        }
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

    public static function getSVGComponent(svg:SVG, x:Float = 0, y:Float = 0, ?width:Int = -1, ?height:Int = -1):SpriteWrapper
    {
        var sprite:Sprite = new Sprite();
        svg.render(sprite.graphics, x, y, width, height);
        return new SpriteWrapper(sprite);
    }

    private static function onResourceLoaded() 
    {
        loadedResourcesCnt++;
        trace('Loaded resource: $loadedResourcesCnt/$totalResourcesCnt');
        if (loadedResourcesCnt == totalResourcesCnt)
            onLoadedCallback();
    }

    public static function load(callback:Void->Void)
    {  
        onLoadedCallback = callback;
        for (fig in PieceType.createAll())
        {
            pieces[fig] = new Map<PieceColor, SVG>();
            for (col in PieceColor.createAll())
                Assets.loadText(piecePath(fig, col)).onComplete(s -> {
                    pieces[fig].set(col, new SVG(s));
                    onResourceLoaded();
                });
        }

        for (type in TimeControlType.createAll())
            Assets.loadText(timeControlPath(type)).onComplete(s -> {
                timeControlIcons.set(type, new SVG(s));
                onResourceLoaded();
            });
    }
}