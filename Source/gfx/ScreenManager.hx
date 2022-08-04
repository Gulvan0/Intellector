package gfx;

import haxe.Timer;
import haxe.ui.Toolkit;
import js.html.VisualViewport;
import haxe.ui.containers.VBox;
import js.html.Element;
import openfl.events.Event;
import dict.Utils;
import gfx.screens.Analysis;
import gfx.screens.LanguageSelectIntro;
import gfx.screens.LiveGame;
import gfx.screens.MainMenu;
import gfx.screens.OpenChallengeJoining;
import gfx.screens.PlayerProfile;
import js.Browser;
import js.html.URLSearchParams;
import net.EventProcessingQueue.INetObserver;
import net.LoginManager;
import net.ServerEvent;
import openfl.display.Sprite;
import struct.ActualizationData;
import struct.PieceColor;
import browser.URLEditor;
import utils.TimeControl;
import haxe.ui.core.Screen as HaxeUIScreen;

using StringTools;

class ScreenManager
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

    public static function getViewedGameID():Null<Int>
    {
        return switch currentScreenType 
        {
            case StartedPlayableGame(gameID, _, _, _, _): gameID;
            case ReconnectedPlayableGame(gameID, _): gameID;
            case SpectatedGame(gameID, _, _): gameID;
            case RevisitedGame(gameID, _, _): gameID;
            default: null;
        }
    }

    public static function disableMenu()
    {
        scene.menubar.disabled = true;
    }

    public static function enableMenu()
    {
        scene.menubar.disabled = false;
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
        }
    }

    private static function handleNetEvent(event:ServerEvent):Bool
    {
        switch event 
        {
            case GameStarted(match_id, enemy, colour, startSecs, bonusSecs):
                var timeControl:TimeControl = new TimeControl(startSecs, bonusSecs);
                var playerColor:PieceColor = PieceColor.createByName(colour);
                var whiteLogin:String = playerColor == White? LoginManager.login : enemy;
                var blackLogin:String = playerColor == Black? LoginManager.login : enemy;
                toScreen(StartedPlayableGame(match_id, whiteLogin, blackLogin, timeControl, playerColor));
            case SpectationData(match_id, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog):
                var timeCorrectionData:TimeCorrectionData = new TimeCorrectionData(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide);
                var actualizationData:ActualizationData = new ActualizationData(currentLog, timeCorrectionData);
                var watchedColor:Null<PieceColor> = White; //TODO: actualizationData.getColor(spectatedPlayerLogin) - Rework using Requests.hx
                toScreen(SpectatedGame(match_id, watchedColor != null? watchedColor : White, actualizationData));
			case ReconnectionNeeded(match_id, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog):
                var timeCorrectionData:TimeCorrectionData = new TimeCorrectionData(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide);
                var actualizationData:ActualizationData = new ActualizationData(currentLog, timeCorrectionData);
                toScreen(ReconnectedPlayableGame(match_id, actualizationData));
            case StudyCreated(studyID, studyName):
                if (currentScreenType.match(Analysis(_, _, _)))
                {
                    //Only change URL and screen data, but do not touch displayed components
                    var newScreenType:ScreenType = Analysis(null, studyID, studyName);
                    URLEditor.setPath(URLEditor.getURLPath(newScreenType), Utils.getScreenTitle(newScreenType));
                    currentScreenType = newScreenType;
                }
            default:
        }
        return false;
    }

    public static function observeNetEvents()
    {
        Networker.eventQueue.addHandler(handleNetEvent);
    }

    public static function launch()
    {
        scene = new Scene();
        HaxeUIScreen.instance.addComponent(scene);

		openflContent = Browser.document.getElementById("openfl-content");
		openflContent.style.width = '${Browser.document.documentElement.clientWidth}px';
        openflContent.style.height = '${Browser.document.documentElement.clientHeight}px';
        lastResizeTimestamp = Date.now().getTime();

        Timer.delay(scene.resize, 40);
        scene.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
}