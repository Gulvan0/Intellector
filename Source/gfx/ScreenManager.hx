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
import haxe.ui.core.Screen;

using StringTools;

/**
    Manages screen transitions (components+URL) and resizing
**/
@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/screen_template.xml'))
class ScreenManager extends VBox implements INetObserver
{
    public static var spectatedPlayerLogin:String; //TODO: Set before sending Spectate event (Rework via Requests.hx?)
    private static var instance:ScreenManager;
    private static var openflContent:Element;

    private var lastResizeTimestamp:Float;
    private var resizeHandlers:Array<Void->Void> = [];

    private var current:Null<IScreen>;
    public static var currentScreenType:Null<ScreenType>;

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

    private static function buildScreen(type:ScreenType):IScreen
    {
        return switch type 
        {
            case MainMenu:
                new MainMenu();
            case Analysis(initialVariantStr, _, _):
                new Analysis(initialVariantStr);
            case LanguageSelectIntro(languageReadyCallback):
                new LanguageSelectIntro(languageReadyCallback);
            case StartedPlayableGame(_, whiteLogin, blackLogin, timeControl, playerColor):
                LiveGame.constructFromParams(whiteLogin, blackLogin, playerColor, timeControl, playerColor);
            case ReconnectedPlayableGame(_, actualizationData):
                LiveGame.constructFromActualizationData(actualizationData);
            case SpectatedGame(_, watchedColor, actualizationData):
                LiveGame.constructFromActualizationData(actualizationData, watchedColor);
            case RevisitedGame(_, watchedColor, data):
                LiveGame.constructFromActualizationData(data, watchedColor);
            case PlayerProfile(ownerLogin):
                new PlayerProfile(ownerLogin);
            case LoginRegister:
                new MainMenu(); //TODO: Change
            case ChallengeJoining(challengeOwner, timeControl, color):
                new OpenChallengeJoining(challengeOwner, timeControl, color);
        };
    }

    private function removeCurrentScreen()
    {
        if (current != null)
        {
            current.onClosed();
            content.removeComponent(current.asComponent());
        }
    }

    public static function toScreen(type:ScreenType)
    {
        instance.removeCurrentScreen();

        currentScreenType = type;

        URLEditor.setPath(URLEditor.getURLPath(type), Utils.getScreenTitle(type));
        instance.current = buildScreen(type);
        instance.menubar.hidden = instance.current.menuHidden();
        instance.content.addComponent(instance.current.asComponent());
        instance.current.onEntered();
    }

    public static function clearScreen()
    {
        instance.removeCurrentScreen();
        URLEditor.clear();
    }

    public static function disableMenu()
    {
        instance.menubar.disabled = true;
    }

    public static function enableMenu()
    {
        instance.menubar.disabled = false;
    }

    public function handleNetEvent(event:ServerEvent)
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
                var watchedColor:Null<PieceColor> = actualizationData.getColor(spectatedPlayerLogin);
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
    }

    public static function addResizeHandler(handler:Void->Void)
    {
        if (instance == null)
            throw "Not initialized";

        instance.resizeHandlers.push(handler);
    }

    public static function removeResizeHandler(handler:Void->Void)
    {
        if (instance == null)
            throw "Not initialized";

        instance.resizeHandlers.remove(handler);
    }

    private function onEnterFrame(e)
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

            for (handler in resizeHandlers)
                Timer.delay(handler, 50);
        }
    }

    public static function launch()
    {
        var screenManager:ScreenManager = new ScreenManager();
        Screen.instance.addComponent(screenManager);
    }

    public static function observeNetEvents()
    {
        Networker.eventQueue.addObserver(instance);
    }
    
    private function new() 
    {
        super();
        instance = this;

        //mainPageLink.customStyle = {fontName: "fonts/Futura.ttf", ...}; //TODO: Rewrite
        //mainPageLink.onClick = e -> {ScreenManager.toScreen(new MainMenu());};

		openflContent = Browser.document.getElementById("openfl-content");
		openflContent.style.width = '${Browser.window.innerWidth}px';
        openflContent.style.height = '${Browser.window.innerHeight}px';
        lastResizeTimestamp = Date.now().getTime();
        
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
}