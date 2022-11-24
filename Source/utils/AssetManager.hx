package utils;

import haxe.ui.util.ImageLoader;
import net.shared.UserStatus;
import gfx.menubar.ChallengesIconMode;
import haxe.CallStack;
import openfl.display.Sprite;
import gfx.basic_components.SpriteWrapper;
import net.shared.TimeControlType;
import format.SVG;
import gfx.analysis.PosEditMode;
import openfl.geom.Matrix;
import struct.Ply;
import struct.Situation;
import struct.Hex;
import openfl.Assets;
import openfl.display.BitmapData;
import net.shared.PieceType;
import net.shared.PieceColor;

enum SingleAsset
{
    StudyTagFilterCross;
    StudyTagLabel;
    AllGamesTimeControlFilterIcon;
    NormalFavicon;
    NotificationFavicon;
}

class AssetManager 
{
    public static var pieces:Map<PieceType, Map<PieceColor, SVG>> = [];

    private static var loadedResourcesCnt:Int = 0;
    private static var totalResourcesCnt:Int = PieceType.createAll().length * PieceColor.createAll().length;
    private static var onLoadedCallback:Void->Void;

    public static inline function singleAssetPath(asset:SingleAsset):String
    {
        var symbolsDir:String = "assets/symbols/";
        var faviconsDir:String = "assets/favicons/";
        return switch asset 
        {
            case StudyTagFilterCross: symbolsDir + "common/study/remove_filter_cross.svg";
            case StudyTagLabel: symbolsDir + "profile/tag.svg";
            case AllGamesTimeControlFilterIcon: symbolsDir + "profile/any_time_control.svg";
            case NormalFavicon: faviconsDir + "normal.png";
            case NotificationFavicon: faviconsDir + "notification.png";
        }
    }

    public static inline function statusPath(status:UserStatus):String
    {
        return "assets/symbols/profile/user_status_indicators/" + status.getName().toLowerCase() + ".svg";
    }

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

    public static inline function timeControlPath(type:TimeControlType):String
    {
        var filename = switch type 
        {
            case Hyperbullet: 'hyperbullet';
            case Bullet: 'bullet';
            case Blitz: 'blitz';
            case Rapid: 'rapid';
            case Classic: 'classic';
            case Correspondence: 'correspondence';
        };

        return 'assets/symbols/time_controls/$filename.svg';
    }

    public static inline function challengeColorPath(ownerOpponentColor:Null<PieceColor>):String
    {
        var filename = switch ownerOpponentColor 
        {
            case White: 'white';
            case Black: 'black';
            case null: 'random';
        };

        return 'assets/symbols/main_menu/challenge_modes/$filename.svg';
    }

    public static inline function challengesMenuIconPath(mode:ChallengesIconMode):String
    {
        var filename = switch mode 
        {
            case Empty: 'none';
            case HasIncoming: 'in';
            case HasOutgoing: 'out';
            case HasBoth: 'both';
        }
        return 'assets/symbols/upper_menu/challenges/button_icon/$filename.svg';
    }

    public static inline function challengesMenuItemArrowPath(isIncoming:Bool):String
    {
        var filename:String = isIncoming? "incoming" : "outgoing";
        return 'assets/symbols/upper_menu/challenges/item_arrow_img/$filename.svg';
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

    private static function onResourceLoaded() 
    {
        loadedResourcesCnt++;
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
    }
}