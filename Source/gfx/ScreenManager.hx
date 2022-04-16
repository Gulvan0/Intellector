package gfx;

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
class ScreenManager extends Sprite implements INetObserver
{
    public static var spectatedPlayerLogin:String; //TODO: Set before sending Spectate event
    private static var instance:ScreenManager;

    public var current:Null<Screen>;

    public function removeCurrentScreen()
    {
        if (current != null)
        {
            current.onClosed();
            removeChild(current);
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
            case StartedPlayableGame(gameID, whiteLogin, blackLogin, timeControl, playerColor):
                LiveGame.constructFromParams(gameID, whiteLogin, blackLogin, playerColor, timeControl, playerColor);
            case ReconnectedPlayableGame(gameID, actualizationData):
                LiveGame.constructFromActualizationData(gameID, actualizationData);
            case SpectatedGame(gameID, watchedColor, actualizationData):
                LiveGame.constructFromActualizationData(gameID, actualizationData, watchedColor);
            case RevisitedGame(gameID, watchedColor, log):
                LiveGame.constructFromActualizationData(gameID, new ActualizationData(log), watchedColor);
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
            case Analysis(initialVariantStr, exploredStudyID): exploredStudyID == null? "analysis" : 'study/$exploredStudyID';
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
        instance.addChild(instance.current);
        instance.current.onEntered();

        return analysisScreen;
    }

    public static function toScreen(type:ScreenType)
    {
        instance.removeCurrentScreen();

        URLEditor.setPath(getURLPath(type), Utils.getScreenTitle(type));
        instance.current = buildScreen(type);
        instance.addChild(instance.current);
        instance.current.onEntered();
    }

    public static function toGameScreen(gameID:Int)
    {
        //TODO: Fill (request additional info from server and process response, then call toScreen with an appropriate argument)
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
                var watchedColor:Null<PieceColor> = actualizationData.logParserOutput.getParticipantColor(spectatedPlayerLogin); //TODO: A bit clumsy approach, try to rethink later
                toScreen(SpectatedGame(match_id, watchedColor != null? watchedColor : White, actualizationData));
			case ReconnectionNeeded(match_id, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog):
                var timeCorrectionData:TimeCorrectionData = new TimeCorrectionData(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide);
                var actualizationData:ActualizationData = new ActualizationData(currentLog, timeCorrectionData);
				toScreen(ReconnectedPlayableGame(match_id, actualizationData));
            default:
        }
    }
	
	/*private function onOngoingGame(data:OngoingBattleData) 
	{
		if (data.whiteLogin.toLowerCase() == Networker.login.toLowerCase())
			data.whiteLogin = Networker.login;
		else if (data.blackLogin.toLowerCase() == Networker.login.toLowerCase())
			data.blackLogin = Networker.login;
		ScreenManager.instance.toGameReconnect(data);
	}*/

    public static function launch(mainInstance:Main)
    {
        var screenManager:ScreenManager = new ScreenManager();
		Networker.eventQueue.addObserver(screenManager);
		mainInstance.addChild(screenManager);
    }
    
    private function new() 
    {
        super();
        instance = this;
    }
}