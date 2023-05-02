package assets;

import gfx.live.analysis.util.PosEditMode;
import gfx.menubar.ChallengesIconMode;
import net.shared.TimeControlType;
import net.shared.PieceColor;
import net.shared.PieceType;
import net.shared.dataobj.UserStatus;

class Paths
{
    public static inline function status(status:UserStatus):String
    {
        return "assets/symbols/profile/user_status_indicators/" + status.getName().toLowerCase() + ".svg";
    }

    public static inline function piece(type:PieceType, color:PieceColor):String
    {
        return "assets/pieces/" + type.getName() + "_" + color.getName() + ".svg";
    }

    public static inline function editModeIcon(mode:PosEditMode):String
    {
        return switch mode {
            case Move: "assets/symbols/analysis/move.svg";
            case Delete: "assets/symbols/analysis/delete.svg";
            case Set(type, color): piece(type, color);
        }
    }

    public static inline function timeControl(type:TimeControlType):String
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

    public static inline function challengeColor(ownerOpponentColor:Null<PieceColor>):String
    {
        var filename = switch ownerOpponentColor 
        {
            case White: 'white';
            case Black: 'black';
            case null: 'random';
        };

        return 'assets/symbols/main_menu/challenge_modes/$filename.svg';
    }

    public static inline function challengesMenuIcon(mode:ChallengesIconMode):String
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

    public static inline function challengesMenuItemArrow(isIncoming:Bool):String
    {
        var filename:String = isIncoming? "incoming" : "outgoing";
        return 'assets/symbols/upper_menu/challenges/item_arrow_img/$filename.svg';
    }

    public static inline function sound(soundName:String)
    {
        return './sounds/$soundName.mp3';
    }
}