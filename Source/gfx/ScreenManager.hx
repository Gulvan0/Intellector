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
import url.URLEditor;
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
            case ChallengeJoining(challengeOwner):
                new OpenChallengeJoining(challengeOwner);
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
            case ChallengeJoining(challengeOwner): 'join/$challengeOwner';
        }
    }

    public static function toStartScreen() 
    {
        //TODO: Either to LanguageSelectIntro or to MainMenu. Is it still needed after the new init logic was introduced?
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

    //TODO: Simplify according to the updated init algrorithm from my notes
    public static function navigateByURL(searchParams:String)
    {
        var searcher = new URLSearchParams(searchParams);
        if (searcher.has("p"))
        {
            var pagePathParts:Array<String> = searcher.get("p").split('/');

            switch pagePathParts[0]
            {
                case "study":  
                    toScreen(Analysis(null, Std.parseInt(pagePathParts[1])));
                case "analysis":  
                    toScreen(Analysis(null, null));
                case "player":  
                    toScreen(PlayerProfile(pagePathParts[1]));
                case "login":  
                    toScreen(LoginRegister);
                case "join": 
                    toScreen(ChallengeJoining(pagePathParts[1]));
                case "live": 
                    var gameID:Null<Int> = Std.parseInt(pagePathParts[1]);
                    if (gameID != null)
                        toGameScreen(gameID);
                    else
                        toStartScreen();
                default:
                    toStartScreen();
            }
        }
        else if (searcher.has("id")) //* These are added for the backward compatibility
			toGameScreen(Std.parseInt(searcher.get("id")));
        else if (searcher.has("ch"))
            toScreen(ChallengeJoining(searcher.get("ch")));
        else
            toStartScreen();

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
            case LoginResult(success):
                if (success) //TODO: Update according to new logic
                    if (LoginManager.wasLastSignInAuto())
                        navigateByURL(Browser.location.search);
                    else
                        toScreen(MainMenu);
            default:
        }
    }
    
    public function new() 
    {
        super();
        instance = this;
    }
}