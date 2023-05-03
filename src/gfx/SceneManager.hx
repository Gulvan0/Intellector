package gfx;

import net.shared.utils.UnixTimestamp;
import dict.Language;
import net.shared.dataobj.ViewedScreen;
import haxe.ui.events.UIEvent;
import net.shared.dataobj.StudyInfo;
import browser.CredentialCookies;
import gfx.Dialogs;
import haxe.Timer;
import haxe.ui.Toolkit;
import js.html.VisualViewport;
import haxe.ui.containers.VBox;
import js.html.Element;
import dict.Utils;
import js.Browser;
import js.html.URLSearchParams;
import net.INetObserver;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import browser.Url;
import utils.TimeControl;
import haxe.ui.core.Screen as HaxeUIScreen;

using StringTools;

class SceneManager
{
    private static var scene:Scene;

    private static var lastResizeTimestamp:Float;
    private static var cachedWidth:Float;
    private static var cachedHeight:Float;
    private static var resizeHandlers:Array<Void->Void> = [];
    private static var resizeTimeout:Null<Timer>;

    public static function playerInGame():Bool
    {
        return scene.playerInGame();
    }

    public static function onDisconnected()
    {
        scene.menubar.disabled = true;
    }

    public static function onConnected()
    {
        scene.menubar.disabled = false;
    }

    public static function onModalDialogShown()
    {
        scene.disabled = true;
    }

    public static function onModalDialogHidden()
    {
        scene.disabled = false;
    }

    public static function toScreen(initializer:ScreenInitializer)
    {
        scene.toScreen(initializer);
    }

    public static function clearScreen()
    {
        scene.toScreen(null);
    }

    public static function addResizeHandler(handler:Void->Void)
    {
        resizeHandlers.push(handler);
    }

    public static function removeResizeHandler(handler:Void->Void)
    {
        resizeHandlers.remove(handler);
    }

    private static function onResized(?e)
    {
        var timestamp:Float = UnixTimestamp.now().toUnixMilliseconds();
        var msSinceLastResize:Float = timestamp - lastResizeTimestamp;

        if (msSinceLastResize > 100 && (cachedWidth != HaxeUIScreen.instance.actualWidth || cachedHeight != HaxeUIScreen.instance.actualHeight))
        {
            lastResizeTimestamp = timestamp;
            cachedWidth = HaxeUIScreen.instance.actualWidth;
            cachedHeight = HaxeUIScreen.instance.actualHeight;

            scene.resize();

            for (handler in resizeHandlers)
                handler();
        }
        else if (resizeTimeout == null)
            resizeTimeout = Timer.delay(onDelayedResizeTimerFired, Math.ceil(100 - msSinceLastResize));
    }

	public static function updateLanguage() 
    {
        scene.updateLanguage();
    }

    private static function onDelayedResizeTimerFired()
    {
        resizeTimeout = null;
        onResized();
    }

    private static function handleNetEvent(event:ServerEvent):Bool
    {
        switch event 
        {
            case GoToGame(data):
                //TODO: Rewrite
                /*if (parsedData.isPlayerParticipant())
                {
                    FollowManager.stopFollowing();
                    constructor = New(parsedData.whiteRef, parsedData.blackRef, parsedData.elo, parsedData.timeControl, parsedData.startingSituation, parsedData.datetime);
                }
                else
                {
                    FollowManager.followedGameID = gameID;
                    constructor = Ongoing(parsedData, null, FollowManager.getFollowedPlayerLogin());
                }
                toScreen(LiveGame(gameID, constructor));*/
            default:
        }
        return false;
    }

    public static function launch():Scene
    {
        scene = new Scene();
        scene.menubar.disabled = true;
        GlobalBroadcaster.addObserver(scene);

        Networker.addHandler(handleNetEvent);
        Networker.addObserver(scene);

        lastResizeTimestamp = UnixTimestamp.now().toUnixMilliseconds();
        cachedWidth = HaxeUIScreen.instance.actualWidth;
        cachedHeight = HaxeUIScreen.instance.actualHeight;

        scene.resize();
        HaxeUIScreen.instance.registerEvent(UIEvent.RESIZE, onResized);

        return scene;
    }
}