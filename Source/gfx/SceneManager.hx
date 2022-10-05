package gfx;

import gfx.game.LiveGameConstructor;
import net.shared.StudyInfo;
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

    public static function playerInGame():Bool
    {
        return scene.playerInGame();
    }

    public static function onConnectionError()
    {
        scene.menubar.disabled = true;

        switch currentScreenType 
        {
            case MainMenu, LiveGame(_, _), PlayerProfile(_, _), ChallengeJoining(_), Analysis(_, _, _, _):
                var removeDialogCallback:Void->Void = Dialogs.reconnectionDialog();
                Networker.startSessionRestorationAttempts(() -> {
                    removeDialogCallback();
                    scene.menubar.disabled = false;
                }, Browser.location.reload.bind(false));
            case LanguageSelectIntro(_), null:
                Browser.location.reload(); //Shouldn't have ended up there, but anyway, let's reload
        }
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

            Timer.delay(broadcastResizeEvent, 40);
        }
    }

    private static function broadcastResizeEvent()
    {
        scene.resize();
        for (handler in resizeHandlers)
            handler();
        Dialogs.onScreenResized();
    }

    public static function updateAnalysisStudyInfo(studyID:Null<Int>, studyInfo:Null<StudyInfo>)
    {
        switch currentScreenType 
        {
            case Analysis(initialVariantStr, selectedMainlineMove, _, _):
                var newScreenType:ScreenType = Analysis(initialVariantStr, selectedMainlineMove, studyID, studyInfo);
                URLEditor.setPath(URLEditor.getURLPath(newScreenType), Utils.getScreenTitle(newScreenType));
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
                    constructor = New(parsedData.whiteLogin, parsedData.blackLogin, parsedData.elo, parsedData.timeControl, parsedData.startingSituation, parsedData.datetime);
                }
                else
                    constructor = Ongoing(parsedData, null, FollowManager.getFollowedPlayerLogin());
                toScreen(LiveGame(gameID, constructor));
            case ReconnectionNeeded(gameID, timeData, currentLog):
                var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                toScreen(LiveGame(gameID, Ongoing(parsedData, timeData, null)));
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