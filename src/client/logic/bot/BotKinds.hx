package client.logic.bot;

import client.datatypes.bot.BotKind;
import engine.hxconda.HxcondaStyle;

/** What each bot kind is called, looks like and plays like **/
class BotKinds
{
    /** In the order the bots are offered **/
    public static final ALL:Array<BotKind> = [STANDARD, TRAILBLAZER, VREZH, FORTRESS, UNCHAINED];

    /** Not localized **/
    public static function displayName(kind:BotKind):String
    {
        return switch kind {
            case STANDARD: "Haxaconda Standard";
            case TRAILBLAZER: "Haxaconda Trailblazer";
            case VREZH: "Haxaconda Vrezh";
            case FORTRESS: "Haxaconda Fortress";
            case UNCHAINED: "Haxaconda Unchained";
        }
    }

    public static function descriptionLocaleKey(kind:BotKind):String
    {
        return 'intellector.common.bot.description.$kind';
    }

    public static function avatarPath(kind:BotKind):String
    {
        var avatarId:String = switch kind {
            case STANDARD: "intellector";
            case TRAILBLAZER: "progressor";
            case VREZH: "aggressor";
            case FORTRESS: "defensor";
            case UNCHAINED: "liberator";
        }
        return 'assets/images/common/bot_avatars/haxaconda/$avatarId.png';
    }

    public static function engineStyle(kind:BotKind):HxcondaStyle
    {
        return switch kind {
            case STANDARD: Standard;
            case TRAILBLAZER: Trailblazer;
            case VREZH: Vrezh;
            case FORTRESS: Fortress;
            case UNCHAINED: Unchained;
        }
    }
}
