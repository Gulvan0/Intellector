package browser;

import haxe.Unserializer;
import haxe.Serializer;
import js.Cookie;
import net.shared.dataobj.ChallengeParams;

class ChallengeParamsCookies
{
    private static inline final cookieName:String = "lastChallengeParams";

    public static function save(params:ChallengeParams)
    {
        Cookie.set(cookieName, Serializer.run(params), 60 * 60 * 24 * 90);
    }

    public static function load():ChallengeParams
    {
        if (Cookie.exists(cookieName))
            return Unserializer.run(Cookie.get(cookieName));
        else
            return ChallengeParams.defaultParams();
    }
}