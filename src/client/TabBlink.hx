package client;

import client.datatypes.TabBlinkReason;
import haxefolio.LocaleUtils;
import haxefolio.browser.Blinker;

/**
    Blinks the browser tab's title and favicon while any reason for it holds, telling the
    highest-ranked one.
**/
class TabBlink
{
    private static inline final FAVICON:String = "assets/favicons/notification.png";

    private static var reasons:Array<TabBlinkReason> = [];
    private static var shownReason:Null<TabBlinkReason> = null;
    private static var blinker:Null<Blinker> = null;

    public static function start(reason:TabBlinkReason):Void
    {
        if (!reasons.contains(reason))
            reasons.push(reason);
        update();
    }

    public static function stop(reason:TabBlinkReason):Void
    {
        reasons.remove(reason);
        update();
    }

    private static function update():Void
    {
        var topReason:Null<TabBlinkReason> = null;
        for (reason in reasons)
            if (topReason == null || reason.getIndex() > topReason.getIndex())
                topReason = reason;

        if (topReason == shownReason)
            return;

        if (blinker != null)
            blinker.stop();

        shownReason = topReason;
        blinker = null;

        if (topReason != null)
        {
            blinker = new Blinker(LocaleUtils.resolveText(GroupedLocaleResolvers.browserTabTitle(topReason)), FAVICON);
            blinker.start();
        }
    }
}
