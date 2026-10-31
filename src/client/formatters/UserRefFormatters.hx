package client.formatters;

import client.datatypes.bot.BotIdentity;
import client.logic.bot.BotKinds;
import client.logic.bot.BotRefs;
import haxefolio.LocaleUtils;

using StringTools;

class UserRefFormatters
{
    private static inline final GUEST_PREFIX:String = "_";
    private static inline final LEGACY_ANACONDA_NAME:String = "Anaconda";

    /**
        The name to show for the user `ref`: a locale binding for guests and known bots, `serverNickname` otherwise.
        Resolve it with `LocaleUtils.resolveText` before using it as a template parameter or in a concatenation.
    **/
    public static function displayName(ref:String, serverNickname:String):String
    {
        if (ref.startsWith(GUEST_PREFIX))
            return LocaleUtils.localeBinding("intellector.common.player.guest_name", guestId(ref));

        var botName:Null<String> = botName(ref);
        if (botName != null)
            return LocaleUtils.localeBinding("intellector.common.player.bot_name", '\'$botName\'');

        return serverNickname;
    }

    /** The English name of the user `ref`, the same in every locale; `nickname` is used for players and unknown bots **/
    public static function englishName(ref:String, nickname:String):String
    {
        if (ref.startsWith(GUEST_PREFIX))
            return 'Guest ${guestId(ref)}';

        var botName:Null<String> = botName(ref);
        if (botName != null)
            return '$botName (Bot)';

        return nickname;
    }

    private static function guestId(ref:String):String
    {
        return ref.substr(GUEST_PREFIX.length);
    }

    /** The name of a known bot, without the bot suffix **/
    private static function botName(ref:String):Null<String>
    {
        if (!BotRefs.isBot(ref))
            return null;

        return switch BotRefs.parse(ref) {
            case Haxaconda(kind, strength): '${BotKinds.displayName(kind)} $strength';
            case LegacyAnaconda: LEGACY_ANACONDA_NAME;
            case Unknown: null;
        }
    }
}
