package client.logic.bot;

import client.datatypes.bot.BotIdentity;
import client.datatypes.bot.BotKind;

using StringTools;

/** Bot user refs: `+hxconda_<kind>_<strength>` for the Haxaconda family **/
class BotRefs
{
    private static inline final PREFIX:String = "+";
    private static inline final HAXACONDA_PREFIX:String = "+hxconda_";
    private static inline final LEGACY_ANACONDA_REF:String = "+Anaconda";

    public static function isBot(ref:String):Bool
    {
        return ref.startsWith(PREFIX);
    }

    public static function build(kind:BotKind, strength:Int):String
    {
        return '$HAXACONDA_PREFIX${kind}_$strength';
    }

    /** `ref` must be a bot's, see `isBot` **/
    public static function parse(ref:String):BotIdentity
    {
        if (ref == LEGACY_ANACONDA_REF)
            return LegacyAnaconda;
        if (!ref.startsWith(HAXACONDA_PREFIX))
            return Unknown;

        var parts:Array<String> = ref.substr(HAXACONDA_PREFIX.length).split("_");
        if (parts.length != 2 || !BotKinds.ALL.contains(parts[0]))
            return Unknown;

        var kind:BotKind = parts[0];
        var strength:Null<Int> = Std.parseInt(parts[1]);
        if (strength == null || Std.string(strength) != parts[1] || !BotStrengthRules.isAvailable(kind, strength))
            return Unknown;

        return Haxaconda(kind, strength);
    }
}
