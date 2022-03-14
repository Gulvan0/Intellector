package gfx;

import net.EventProcessingQueue.INetObserver;
import js.Browser;
import net.ServerEvent;
import gfx.screens.Screen;
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

    public static function toScreen(screen:Screen)
    {
        instance.removeCurrentScreen();

        URLEditor.setPath(screen.getURLPath());
        instance.current = screen;
        instance.addChild(instance.current);
        instance.current.onEntered();
    }

    public static function clearScreen()
    {
        instance.removeCurrentScreen();
        URLEditor.clear();
    }

    public static function navigateByURL(searchParams:String)
    {
        //TODO: Fill (you call it after logging in)
    }

    //For the navigateByURL method (rewrite)
    /*public static function getShallowSection()
    {
        var searcher = new URLSearchParams(Browser.location.search);
        if (searcher.has("id"))
			return Game(Std.parseInt(searcher.get("id")));
        else if (searcher.has("ch"))
            return OpenChallengeInvitation(searcher.get("ch"));
        else
			return Main;
    }*/

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case GameStarted(match_id, enemy, colour, startSecs, bonusSecs):
                //TODO: Fill
            case SpectationData(match_id, whiteLogin, blackLogin, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog):
                //TODO: Uncomment
                //toScreen(new Spectation(match_id, whiteLogin, blackLogin, whiteSeconds, blackSeconds, timestamp, pingSubtractionSide, currentLog));
            case LoginResult(success):
                if (success)
                    if (LoginManager.wasLastSignInAuto())
                        navigateByURL(Browser.location.search);
                    else
                        toScreen(new MainMenu());
            default:
        }
    }
    /* 
    //TODO: Rewrite. Pass ServerEvent constructor parameters. Create and use corresponding screen instead of GameCompound
    public function toGameStart(data:Dynamic) 
    {
        toGameGeneric(data.match_id, GameCompound.buildActive(data, onReturnPressed));
    }

    /*
        var playerColor:PieceColor;
        if (LoginManager.isPlayer(whiteLogin))
            playerColor = White;
        else if (LoginManager.isPlayer(blackLogin))
            playerColor = Black;
        else
            throw "initPlayable() called, but player not found among the participants";
    *//*

    //TODO: Rewrite. Pass ServerEvent constructor parameters. Create and use corresponding screen instead of GameCompound
    public function toGameReconnect(match_id:Int, whiteLogin:String, blackLogin:String, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String, currentLog:String) 
    {
        toGameGeneric(data.match_id, GameCompound.buildActiveReconnect(data, onReturnPressed));
    }

    //TODO: Rewrite. Create and use corresponding screen instead of GameCompound
    private function toGameGeneric(id:Int, game:GameCompound) 
    {
        //TODO: To OnlineGame init + rewrite
        current = game;
        Networker.currentGameCompound = game;
        Networker.disableMainMenuEvents();
		Networker.enableIngameEvents(onGameEnded);

		Assets.getSound("sounds/notify.mp3").play();
    }

    //TODO: Rewrite. Create and use corresponding screen instead of GameCompound

    public function toSpectation(match_id:Int, whiteLogin:String, blackLogin:String, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String, currentLog:String) 
	{
		clear();
        URLEditor.assignID(match_id);

        var playerIsWhite:Bool = LoginManager.isPlayer(whiteLogin);
        var spectatedLogin:String = playerIsWhite? whiteLogin : blackLogin;

        //TODO: Rewrite. Create and use corresponding screen instead of GameCompound
        var game = GameCompound.buildSpectators(data, () -> 
        {
            Networker.stopSpectation(); 
            Networker.currentGameCompound = null;
		    toMain();
        }, Spectator(spectatedLogin));
        
		current = game;
        Networker.currentGameCompound = game;
        Networker.enableMainMenuEvents((data) -> {
            Networker.stopSpectation(); 
            Networker.currentGameCompound = null;
            toGameStart(data);
        });
        Networker.enableSpectationEvents((data) -> {
            Networker.disableSpectationEvents();
            Networker.currentGameCompound.terminate(data);
        });
        addChild(current);
    }
    
    //TODO: Rewrite. Create and use corresponding screen instead of GameCompound
    public function toRevisit(id:Int, log:String, onReturn:Void->Void) 
    {
        clear();
        URLEditor.assignID(id);
        var ereg:EReg = ~/#P\|([A-Za-z0-9_]*):([A-Za-z0-9_]*);/;
        ereg.match(log);

        var mockData:OngoingBattleData = {
            match_id: id, 
            requestedColor: 'white', 
            whiteLogin: ereg.matched(1), 
            blackLogin: ereg.matched(2), 
            whiteSeconds: null, 
            blackSeconds: null, 
            timestamp: 0,
            pingSubtractionSide: "",
            position: null,
            currentLog: log
        };

        current = GameCompound.buildSpectators(mockData, onReturn, Revisit(id));
        addChild(current);
    }
    
    //TODO: Rewrite. Pass ServerEvent constructor parameters
    private function onGameEnded(data:Dynamic) 
	{
        var playerColor:PieceColor = Networker.currentGameCompound.playerColor;
        var playerIsWinner:Bool = data.winner_color == letter(playerColor);
		Networker.currentGameCompound.terminate(data);
		Networker.currentGameCompound = null;

		var resultMessage;
		if (data.winner_color == "d")
			resultMessage = "½ - ½";
		else if (playerIsWinner)
			resultMessage = Dictionary.getPhrase(WIN_MESSAGE_PREAMBLE);
		else 
			resultMessage = Dictionary.getPhrase(LOSS_MESSAGE_PREAMBLE);

        var explanation = Utils.getGameOverExplanation(data.reason);
        
        Networker.disableIngameEvents();
        Networker.enableMainMenuEvents(toGameStart);

        Assets.getSound("sounds/notify.mp3").play();
        if (data.reason == 'abort')
            Dialogs.info(Dictionary.getPhrase(GAME_OVER_REASON_ABORT), Dictionary.getPhrase(GAME_ENDED));
        else
		    Dialogs.info(Dictionary.getPhrase(GAME_OVER) + resultMessage + explanation, Dictionary.getPhrase(GAME_ENDED));
	}
    */
    public function new() 
    {
        super();
        instance = this;
    }
}