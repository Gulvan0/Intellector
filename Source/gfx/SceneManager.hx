package gfx;

import net.shared.dataobj.ViewedScreen;
import haxe.ui.events.UIEvent;
import gfx.game.LiveGameConstructor;
import net.shared.dataobj.StudyInfo;
import gfx.game.LiveGameConstructor;
import browser.CredentialCookies;
import gfx.Dialogs;
import serialization.GameLogParser;
import haxe.Timer;
import haxe.ui.Toolkit;
import js.html.VisualViewport;
import haxe.ui.containers.VBox;
import js.html.Element;
import openfl.events.Event;
import dict.Utils;
import js.Browser;
import js.html.URLSearchParams;
import net.EventProcessingQueue.INetObserver;
import net.shared.ServerEvent;
import openfl.display.Sprite;
import net.shared.PieceColor;
import browser.Url;
import utils.TimeControl;
import haxe.ui.core.Screen as HaxeUIScreen;

using StringTools;

class SceneManager
{
    private static var scene:Scene;
    private static var currentScreenType:Null<ScreenType> = null;

    private static var lastResizeTimestamp:Float;
    private static var cachedWidth:Float;
    private static var cachedHeight:Float;
    private static var resizeHandlers:Array<Void->Void> = [];
    private static var resizeTimeout:Null<Timer>;

    public static function getCurrentScreenType():Null<ScreenType>
    {
        return currentScreenType;
    }

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

    public static function toScreen(type:ScreenType)
    {
        scene.toScreen(type);
        currentScreenType = type;
        Url.setPathByScreen(type);
        Networker.emitEvent(PageUpdated(getPageByScreenType(type)));
    }

    private static function getPageByScreenType(type:ScreenType):ViewedScreen
    {
        return switch type 
        {
            case MainMenu: MainMenu;
            case Analysis(_, _, _, _): Analysis;
            case LanguageSelectIntro(_): Other;
            case LiveGame(gameID, _): Game(gameID);
            case PlayerProfile(ownerLogin, _): Profile(ownerLogin);
            case ChallengeJoining(_): Other;
        }
    }

    public static function clearScreen()
    {
        scene.toScreen(null);
        currentScreenType = null;
        Url.clear();
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
        var timestamp:Float = Date.now().getTime();
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

    private static function onDelayedResizeTimerFired()
    {
        resizeTimeout = null;
        onResized();
    }

    public static function updateAnalysisStudyInfo(studyID:Null<Int>, studyInfo:Null<StudyInfo>)
    {
        switch currentScreenType 
        {
            case Analysis(initialVariantStr, selectedMainlineMove, _, _):
                var newScreenType:ScreenType = Analysis(initialVariantStr, selectedMainlineMove, studyID, studyInfo);
                Url.setPathByScreen(newScreenType);
                currentScreenType = newScreenType;
            default:
                throw "Cannot update study info outside of analysis screen";
        }
    }

    private static function handleNetEvent(event:ServerEvent):Bool
    {
        switch event 
        {
            case GameStarted(gameID, logPreamble):
                var parsedData:GameLogParserOutput = GameLogParser.parse(logPreamble);
                var constructor:LiveGameConstructor;
                if (parsedData.isPlayerParticipant())
                {
                    FollowManager.stopFollowing();
                    constructor = New(parsedData.whiteRef, parsedData.blackRef, parsedData.elo, parsedData.timeControl, parsedData.startingSituation, parsedData.datetime);
                }
                else
                    constructor = Ongoing(parsedData, null, FollowManager.getFollowedPlayerLogin());
                toScreen(LiveGame(gameID, constructor));
            default:
        }
        return false;
    }

    public static function launch()
    {
        scene = new Scene();
        scene.menubar.disabled = true;
        HaxeUIScreen.instance.addComponent(scene);
        GlobalBroadcaster.addObserver(scene);

        Networker.addHandler(handleNetEvent);
        Networker.addObserver(scene);

        lastResizeTimestamp = Date.now().getTime();
        cachedWidth = HaxeUIScreen.instance.actualWidth;
        cachedHeight = HaxeUIScreen.instance.actualHeight;

        scene.resize();
        HaxeUIScreen.instance.registerEvent(UIEvent.RESIZE, onResized);
    }
}