package client.ui.profile;

import haxefolio.ResponsivityController;
import morestd.Detachable;

/**
    The profile page's tier scale. Wide: the aside is a column right of the games. Medium: the aside
    goes above them, its cards collapsed into bars. Narrow: the header's buttons share the full width.
**/
enum abstract ProfileLayoutTier(String) from String to String
{
    var Narrow = "narrow";
    var Medium = "medium";
    var Wide = "wide";

    /** The scale's name, as registered with HaxeFolio and carried by the `haxefolio-tier-profile-<tier>` root classes **/
    public static inline final SCALE:String = "profile";

    public static inline final MEDIUM_MIN_WIDTH:Int = 720;
    public static inline final WIDE_MIN_WIDTH:Int = 960;

    /** Calls `apply` with the current tier now and whenever it changes; detach the handle on disposal **/
    public static function bind(apply:ProfileLayoutTier->Void):Detachable
    {
        return ResponsivityController.bindTier(SCALE, tier -> apply(tier));
    }
}
