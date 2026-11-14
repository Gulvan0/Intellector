package client.ui.games;

import haxefolio.ResponsivityController;
import morestd.Detachable;

/** The game database page's tier scale. Narrow: phone layouts, value selectors as full-screen sheets **/
enum abstract GamesLayoutTier(String) from String to String
{
    var Narrow = "narrow";
    var Wide = "wide";

    /** The scale's name, as registered with HaxeFolio **/
    public static inline final SCALE:String = "games";

    public static inline final WIDE_MIN_WIDTH:Int = 720;

    /** Calls `apply` with the current tier now and whenever it changes; detach the handle on disposal **/
    public static function bind(apply:GamesLayoutTier->Void):Detachable
    {
        return ResponsivityController.bindTier(SCALE, tier -> apply(tier));
    }
}
