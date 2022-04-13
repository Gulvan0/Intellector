package gfx;

import gfx.screens.LanguageSelectIntro;
import gfx.screens.LiveGame;
import gfx.screens.Analysis;
import net.EventProcessingQueue.INetObserver;
import js.Browser;
import net.ServerEvent;
import net.LoginManager;
import struct.Situation;
import struct.ReversiblePly;
import gfx.components.Dialogs;
import gfx.screens.PlayerProfile;
import struct.PieceColor;
import gfx.screens.MainMenu;
import gfx.screens.Settings;
import dict.Dictionary;
import dict.Utils;
import gfx.screens.OpenChallengeHosting;
import openfl.Assets;
import gfx.screens.OpenChallengeJoining;
import url.URLEditor;
import url.Utils as URLUtils;
import haxe.ui.components.Label;
import gfx.screens.SignIn;
import openfl.display.Sprite;
using StringTools;

/**
    Manages state transition correctness (both for url and for displayed objects)
**/
class ScreenManager extends Sprite implements INetObserver
{
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
            case PlayableGame(gameID, whiteLogin, blackLogin, timeControl, playerColor, pastLog):
                new LiveGame(gameID, whiteLogin, blackLogin, playerColor, timeControl.startSecs, timeControl.bonusSecs, playerColor, pastLog);
            case SpectatedGame(gameID, whiteLogin, blackLogin, watchedColor, timeControl, pastLog):
                new LiveGame(gameID, whiteLogin, blackLogin, watchedColor, timeControl.startSecs, timeControl.bonusSecs, null, pastLog);
            case RevisitedGame(gameID, whiteLogin, blackLogin, watchedColor, timeControl, log):
                new LiveGame(gameID, whiteLogin, blackLogin, watchedColor, timeControl.startSecs, timeControl.bonusSecs, null, log);
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
            case PlayableGame(gameID, whiteLogin, blackLogin, timeControl, playerColor, pastLog): 'live/$gameID';
            case SpectatedGame(gameID, whiteLogin, blackLogin, watchedColor, timeControl, pastLog): 'live/$gameID';
            case RevisitedGame(gameID, whiteLogin, blackLogin, watchedColor, timeControl, log): 'live/$gameID';
            case PlayerProfile(ownerLogin): 'player/$ownerLogin';
            case LoginRegister: 'login';
            case ChallengeHosting(_, _): "challenge";
            case ChallengeJoining(challengeOwner): 'join/$challengeOwner';
        }
    }

    public static function toStartScreen() 
    {
        //TODO: Either to LanguageSelectIntro or to MainMenu
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

    //TODO: Decide where to put check logic (is logged in? has language selected? player/game exists?) whilist also trying to simplify this method
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
                var playerColor:PieceColor = PieceColor.createByName(playerColor);
                var whiteLogin:String = playerColor == White? LoginManager.login : enemy;
                var blackLogin:String = playerColor == Black? LoginManager.login : enemy;
                toScreen(PlayableGame(match_id, whiteLogin, blackLogin, timeControl, playerColor, null));
            case SpectationData(match_id, whiteLogin, blackLogin, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog):
                //TODO: Uncomment while also solving these problems:
                //? Why isn't there a timeControl parameter?
                //? Time correction upon creation is impossible?!
                //toScreen(SpectatedGame(match_id, whiteLogin, blackLogin, watchedColor, timeControl, currentLog));
            case LoginResult(success):
                if (success)
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