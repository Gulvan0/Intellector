package browser;

import haxe.ui.core.Screen;
import js.html.LinkElement;
import haxe.ui.ToolkitAssets;
import js.Browser;
import utils.AssetManager;
import haxe.ui.HaxeUIApp;
import haxe.Timer;
import dict.Dictionary;

enum BlinkerNotification
{
    IncomingChallenge;
    GameStarted;
}

class Blinker
{
    private static var notificationTitle:String;
    private static var specialTitleDisplayed:Bool = false;
    private static var blinkTimer:Null<Timer>;

    private static function setIcon(path:String) 
    {
        var link:LinkElement = cast Browser.document.querySelector("link[rel~='icon']");

        if (link == null) 
        {
            link = Browser.document.createLinkElement();
            link.rel = "icon";
            Browser.document.getElementsByTagName('head')[0].appendChild(link);
        }
        
        link.href = path;
    }

    private static function onBlinked() 
    {
        if (specialTitleDisplayed)
        {
            setIcon(AssetManager.singleAssetPath(NormalFavicon));
            Screen.instance.title = Url.getCurrentTitle();
        }
        else
        {
            setIcon(AssetManager.singleAssetPath(NotificationFavicon));
            Screen.instance.title = notificationTitle;
        }

        specialTitleDisplayed = !specialTitleDisplayed;
    }

    public static function init() 
    {
        Browser.document.onvisibilitychange = () -> {
            if (Browser.document.visibilityState == VISIBLE)
                resetBlinking();
        }
    }

    public static function blink(notification:BlinkerNotification) 
    {
        if (Browser.document.visibilityState != HIDDEN)
            return;

        notificationTitle = Dictionary.getPhrase(NOTIFICATION_BROWSER_TAB_TITLE(notification));

        if (blinkTimer == null)
        {
            blinkTimer = new Timer(1000);
            blinkTimer.run = onBlinked;
        }
    }

    private static function resetBlinking()
    {
        if (blinkTimer != null)
            blinkTimer.stop();

        blinkTimer = null;

        setIcon(AssetManager.singleAssetPath(NormalFavicon));
        Screen.instance.title = Url.getCurrentTitle();

        specialTitleDisplayed = false;
    }
}