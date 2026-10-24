package client.ui.home;

import haxefolio.ResponsivityController;
import morestd.Detachable;

/** The home page's tier scale. Narrow: one games section at a time, switched by tabs; the rows and cards take their phone layouts **/
enum abstract HomeLayoutTier(String) from String to String
{
    var Narrow = "narrow";
    var Wide = "wide";

    /** The scale's name, as registered with HaxeFolio **/
    public static inline final SCALE:String = "home";

    public static inline final WIDE_MIN_WIDTH:Int = 720;

    /** Calls `apply` with the current tier now and whenever it changes; detach the handle on disposal **/
    public static function bind(apply:HomeLayoutTier->Void):Detachable
    {
        return ResponsivityController.bindTier(SCALE, tier -> apply(tier));
    }
}
