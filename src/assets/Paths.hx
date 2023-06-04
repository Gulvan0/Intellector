package assets;

import gfx.menu.MenuItemName;
import gfx.game.analysis.util.PosEditMode;
import gfx.menu.challenges.ChallengesIconMode;
import net.shared.TimeControlType;
import net.shared.PieceColor;
import net.shared.PieceType;
import net.shared.dataobj.UserStatus;

class Paths
{
    public static inline function status(status:UserStatus):String
    {
        return "assets/images/profile/simple_components/user_status_indicators/" + status.getName().toLowerCase() + ".svg";
    }

    public static inline function piece(type:PieceType, color:PieceColor):String
    {
        return "assets/pieces/" + type.getName() + "_" + color.getName() + ".svg";
    }

    public static inline function editModeIcon(mode:PosEditMode):String
    {
        return switch mode {
            case Move: "assets/images/game/analysis/move.svg";
            case Delete: "assets/images/common/delete.svg";
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

        return 'assets/images/common/challenge_modes/$filename.svg';
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
        return 'assets/images/menu/challenges/button_icon/$filename.svg';
    }

    public static inline function challengesMenuItemArrow(isIncoming:Bool):String
    {
        var filename:String = isIncoming? "incoming" : "outgoing";
        return 'assets/images/menu/challenges/item_arrow_img/$filename.svg';
    }

    public static inline function sound(soundName:String)
    {
        return './sounds/$soundName.mp3';
    }

    public static inline function menuItem(name:MenuItemName) 
    {
        var fileName:String = switch name 
        {
            case CreateChallenge: 'new_game';
            case OpenChallenges: 'open_challenges';
            case PlayVersusBot: 'versus_bot';
            case CurrentGames: 'current_games';
            case FollowPlayer: 'watch_player';
            case AnalysisBoard: 'analysis_board';
            case PlayerProfile: 'player_profile';
            case DiscordServer: 'discord';
            case VKGroup: 'vk';
            case VKChat: 'vk';
        }

        return 'assets/images/menu/menu_items/' + fileName + '.svg';
    }
}