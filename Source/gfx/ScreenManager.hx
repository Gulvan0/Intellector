package gfx;

import haxe.ui.containers.Box;
import js.html.Element;
import openfl.events.Event;
import dict.Utils;
import gfx.screens.Analysis;
import gfx.screens.LanguageSelectIntro;
import gfx.screens.LiveGame;
import gfx.screens.MainMenu;
import gfx.screens.OpenChallengeHosting;
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

using StringTools;

/**
    Manages state transition correctness (both for url and for displayed objects)
**/
class ScreenManager extends Box implements INetObserver
{
    public static var spectatedPlayerLogin:String; //TODO: Set before sending Spectate event
    public static var instance:ScreenManager;
    private static var openflContent:Element;

    private var lastResizeTimestamp:Float;

    public var current:Null<Screen>;
    public static var viewedGameID:Null<Int> = null;

    public function removeCurrentScreen()
    {
        if (current != null)
        {
            current.onClosed();
            removeComponent(current);
        }
    }

    private static function buildScreen(type:ScreenType):Screen
    {
        return switch type 
        {
            case MainMenu:
                new MainMenu();
            case Analysis(initialVariantStr, exploredStudyID):
                new Analysis(initialVariantStr, exploredStudyID);
            case LanguageSelectIntro:
                new LanguageSelectIntro();
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
                new Screen(); //TODO: Change
            case ChallengeHosting(timeControl, color):
                new OpenChallengeHosting(timeControl, color);
            case ChallengeJoining(challengeOwner, timeControl, color):
                new OpenChallengeJoining(challengeOwner, timeControl, color);
        };
    }

    private static function getURLPath(type:ScreenType):String
    {
        return switch type 
        {
            case MainMenu: "home";
            case Analysis(_, exploredStudyID): exploredStudyID == null? "analysis" : 'study/$exploredStudyID';
            case LanguageSelectIntro: "";
            case StartedPlayableGame(gameID, _, _, _, _): 'live/$gameID';
            case ReconnectedPlayableGame(gameID, _): 'live/$gameID';
            case SpectatedGame(gameID, _, _): 'live/$gameID';
            case RevisitedGame(gameID, _, _): 'live/$gameID';
            case PlayerProfile(ownerLogin): 'player/$ownerLogin';
            case LoginRegister: 'login';
            case ChallengeHosting(_, _): "challenge";
            case ChallengeJoining(challengeOwner, timeControl, color): 'join/$challengeOwner';
        }
    }

    /**Use when a connection to a server cannot be estabilished**/
    public static function toOfflineAnalysis():Analysis
    {
        instance.removeCurrentScreen();

        var analysisScreen:Analysis = new Analysis();
        analysisScreen.disableMenu();

        instance.current = analysisScreen;
        instance.addComponent(instance.current);
        instance.current.onEntered();

        return analysisScreen;
    }

    public static function toScreen(type:ScreenType)
    {
        instance.removeCurrentScreen();

        viewedGameID = switch type 
        {
            case StartedPlayableGame(gameID, _, _, _, _): gameID;
            case ReconnectedPlayableGame(gameID, _): gameID;
            case SpectatedGame(gameID, _, _): gameID;
            case RevisitedGame(gameID, _, _): gameID;
            default: null;
        }

        URLEditor.setPath(getURLPath(type), Utils.getScreenTitle(type));
        instance.current = buildScreen(type);
        instance.addComponent(instance.current);
        instance.current.onEntered();
    }

    public static function clearScreen()
    {
        instance.removeCurrentScreen();
        URLEditor.clear();
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
            default:
        }
    }

    private function onEnterFrame(e:Event)
    {
        var timestamp:Float = Date.now().getTime();
        if (timestamp - lastResizeTimestamp > 100)
        {
            var innerWidthStr = '${Browser.window.innerWidth}px';
            var innerHeightStr = '${Browser.window.innerHeight}px';

            if (openflContent.style.width == innerWidthStr && openflContent.style.height == innerHeightStr)
                return;

            openflContent.style.width = innerWidthStr;
            openflContent.style.height = innerHeightStr;
            lastResizeTimestamp = timestamp;
            trace(innerWidthStr, innerHeightStr);
        }
    }

    public static function launch()
    {
        var screenManager:ScreenManager = new ScreenManager();
        haxe.ui.core.Screen.instance.addComponent(screenManager);
    }

    public static function observeNetEvents()
    {
        Networker.eventQueue.addObserver(instance);
    }
    
    private function new() 
    {
        super();
        instance = this;

		openflContent = Browser.document.getElementById("openfl-content");
		openflContent.style.width = '${Browser.window.innerWidth}px';
        openflContent.style.height = '${Browser.window.innerHeight}px';
        lastResizeTimestamp = Date.now().getTime();
        
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
}