package gfx;

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
import struct.PieceColor;
import browser.URLEditor;
import utils.TimeControl;
import haxe.ui.core.Screen as HaxeUIScreen;

using StringTools;

class SceneManager
{
    private static var scene:Scene;
    private static var currentScreenType:Null<ScreenType> = null;
    private static var openflContent:Element;

    private static var lastResizeTimestamp:Float;
    private static var resizeHandlers:Array<Void->Void> = [];

    public static function getCurrentScreenType():Null<ScreenType>
    {
        return currentScreenType;
    }

    public static function onConnectionError()
    {
        scene.menubar.disabled = true;

        var cleanupCallback:Null<Void->Void> = null;

        switch currentScreenType 
        {
            case MainMenu, LiveGame(_, _), PlayerProfile(_), ChallengeJoining(_):
                cleanupCallback = Dialogs.reconnectionDialog();
            case Analysis(_, _, _, _):
                //* Do nothing
            case LanguageSelectIntro(_), null:
                toScreen(Analysis(null, null, null, null));
        }
		
		Networker.startReconnectAttempts(onReconnected.bind(cleanupCallback));
    }

    private static function onReconnected(cleanupCallback:Null<Void->Void>)
    {
        if (cleanupCallback != null)
            cleanupCallback();
        scene.menubar.disabled = false;
        if (CredentialCookies.hasLoginDetails())
            LoginManager.signin(CredentialCookies.getLogin(), CredentialCookies.getPassword(), null, ()->{}, ()->{});
    }

    public static function toScreen(type:ScreenType)
    {
        scene.toScreen(type);
        currentScreenType = type;
        URLEditor.setPath(URLEditor.getURLPath(type), Utils.getScreenTitle(type));
    }

    public static function clearScreen()
    {
        scene.toScreen(null);
        currentScreenType = null;
        URLEditor.clear();
    }

    public static function addResizeHandler(handler:Void->Void)
    {
        resizeHandlers.push(handler);
    }

    public static function removeResizeHandler(handler:Void->Void)
    {
        resizeHandlers.remove(handler);
    }

    private static function onEnterFrame(e)
    {
        var timestamp:Float = Date.now().getTime();
        if (timestamp - lastResizeTimestamp > 100)
        {
            var innerWidthStr = '${Browser.document.documentElement.clientWidth}px';
            var innerHeightStr = '${Browser.document.documentElement.clientHeight}px';

            if (openflContent.style.width == innerWidthStr && openflContent.style.height == innerHeightStr)
                return;

            openflContent.style.width = innerWidthStr;
            openflContent.style.height = innerHeightStr;
            lastResizeTimestamp = timestamp;

            Timer.delay(scene.resize, 40);
            for (handler in resizeHandlers)
                Timer.delay(handler, 40);
            Timer.delay(Dialogs.onScreenResized, 40);
        }
    }

    private static function handleNetEvent(event:ServerEvent):Bool
    {
        switch event 
        {
            case GameStarted(match_id, logPreamble):
                var parsedData:GameLogParserOutput = GameLogParser.parse(logPreamble);
                toScreen(LiveGame(match_id, New(parsedData.whiteLogin, parsedData.blackLogin, parsedData.timeControl, parsedData.startingSituation, parsedData.datetime)));
            case FollowPlayerGameStarted(match_id, followedPlayerLogin, logPreamble):
                var parsedData:GameLogParserOutput = GameLogParser.parse(logPreamble);
                toScreen(LiveGame(match_id, Ongoing(parsedData, parsedData.timeControl.startSecs, parsedData.timeControl.startSecs, Date.now().getTime(), followedPlayerLogin)));
            case ReconnectionNeeded(match_id, whiteSeconds, blackSeconds, timestamp, currentLog):
                var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                toScreen(LiveGame(match_id, Ongoing(parsedData, whiteSeconds, blackSeconds, timestamp, null)));
            case StudyCreated(studyID, studyName):
                if (currentScreenType.match(Analysis(_, _, _)))
                {
                    //Only change URL and screen data, but do not touch displayed components
                    var newScreenType:ScreenType = Analysis(null, null, studyID, studyName);
                    URLEditor.setPath(URLEditor.getURLPath(newScreenType), Utils.getScreenTitle(newScreenType));
                    currentScreenType = newScreenType;
                }
            default:
        }
        return false;
    }

    public static function observeNetEvents()
    {
        Networker.addHandler(handleNetEvent);
        Networker.addObserver(scene);
    }

    public static function launch()
    {
        scene = new Scene();
        HaxeUIScreen.instance.addComponent(scene);
        GlobalBroadcaster.addObserver(scene);

		openflContent = Browser.document.getElementById("openfl-content");
		openflContent.style.width = '${Browser.document.documentElement.clientWidth}px';
        openflContent.style.height = '${Browser.document.documentElement.clientHeight}px';
        lastResizeTimestamp = Date.now().getTime();

        Timer.delay(scene.resize, 40);
        scene.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
}