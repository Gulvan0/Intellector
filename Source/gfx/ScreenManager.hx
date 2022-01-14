package gfx;

import struct.Situation;
import struct.ReversiblePly;
import gfx.components.gamefield.AnalysisCompound;
import gfx.components.Dialogs;
import gfx.components.gamefield.GameCompound;
import gfx.screens.PlayerProfile;
import struct.PieceColor;
import gfx.screens.MainMenu;
import gfx.screens.Settings;
import dict.Dictionary;
import gfx.screens.OpenChallengeHosting;
import openfl.Assets;
import gfx.screens.OpenChallengeJoining;
import url.URLEditor;
import haxe.ui.components.Label;
import gfx.screens.SignIn;
import openfl.display.Sprite;
using StringTools;

/**
    Manages state transition correctness (both for url and for displayed objects)
**/
class ScreenManager extends Sprite
{
    public static var instance:ScreenManager;

    public var current:Null<Sprite>;
    private var changes:Label;

    private function clear() 
    {
        if (current != null)
            removeChild(current);
        removeChild(changes);
    }

    public function toEmpty()
    {
        clear();
        URLEditor.clear();
    }

    public function toSignIn()
    {
        clear();
        URLEditor.clear();

        current = new SignIn();
        addChild(current);
        addChild(changes);
    }

    public function toMain() 
    {
        clear();
        URLEditor.clear();
        Networker.disableIngameEvents();
        Networker.disableSpectationEvents();
        Networker.enableMainMenuEvents(toGameStart);
        
        current = new MainMenu();
        addChild(current);
        addChild(changes);
    }

    //TODO: Rewrite. Pass ServerEvent constructor parameters. Create and use corresponding screen instead of GameCompound
    public function toGameStart(data:Dynamic) 
    {
        var isGuest = Networker.login.startsWith("guest_");
        var onReturnPressed = isGuest? Networker.dropConnection : toMain;
        toGameGeneric(data.match_id, GameCompound.buildActive(data, onReturnPressed));
    }

    //TODO: Rewrite. Pass ServerEvent constructor parameters. Create and use corresponding screen instead of GameCompound
    public function toGameReconnect(data:Dynamic) 
    {
        var isGuest = Networker.login.startsWith("guest_");
        var onReturnPressed = isGuest? Networker.dropConnection : toMain;
        toGameGeneric(data.match_id, GameCompound.buildActiveReconnect(data, onReturnPressed));
    }

    //TODO: Rewrite. Create and use corresponding screen instead of GameCompound
    private function toGameGeneric(id:Int, game:GameCompound) 
    {
        clear();
        URLEditor.assignID(id);

        current = game;
        Networker.currentGameCompound = game;
        Networker.disableMainMenuEvents();
		Networker.enableIngameEvents(onGameEnded);

		Assets.getSound("sounds/notify.mp3").play();
        addChild(current);
    }

    public function toOpenChallengeHostingRoom(startSecs:Int, bonusSecs:Int, color:Null<PieceColor>) 
    {
        clear();
        URLEditor.clear();
        
        current = new OpenChallengeHosting(startSecs, bonusSecs, color);
        addChild(current);
    }

    //TODO: Rewrite. Pass ServerEvent constructor parameters
    public function toOpenChallengeJoiningRoom(data:Dynamic) 
    {
        clear();
        URLEditor.clear();
        
        current = new OpenChallengeJoining(data);
        addChild(current);
    }

    //TODO: Rewrite. Create and use corresponding screen instead of GameCompound
    public function toAnalysisBoard(onReturn:Void->Void, ?study:StudyOverview, ?situationSIP:String) 
    {
        clear();
        URLEditor.clear();
        
        current = new AnalysisCompound(() ->
        {
            Networker.currentGameCompound = null;
		    onReturn();
        }, study, situationSIP);
        addChild(current);
    }

    //TODO: Rewrite. Pass ServerEvent constructor parameters. Create and use corresponding screen instead of GameCompound
    public function toSpectation(data:Dynamic) 
	{
		clear();
        URLEditor.assignID(data.match_id);

        var spectatedLogin:String = data.requestedColor == 'white'? data.whiteLogin : data.blackLogin;
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

    public function toProfile(login:String, onReturn:Void->Void, onNotExists:Void->Void):Void
    {
        Networker.checkPlayerExistance(login, exists -> {
            if (exists)
            {
                clear();
                URLEditor.assignProfileLogin(login);

                current = new PlayerProfile(login, onReturn);
                addChild(current);
            }
            else
                onNotExists();
        });
    }

    public function toSettings() 
    {
        clear();
        URLEditor.clear();
        
        current = new Settings();
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

        var explanation = Dictionary.getGameOverExplanation(data.reason);
        
        Networker.disableIngameEvents();
        Networker.enableMainMenuEvents(toGameStart);

        Assets.getSound("sounds/notify.mp3").play();
        if (data.reason == 'abort')
            Dialogs.info(Dictionary.getPhrase(GAME_OVER_REASON_ABORT), Dictionary.getPhrase(GAME_ENDED));
        else
		    Dialogs.info(Dictionary.getPhrase(GAME_OVER) + resultMessage + explanation, Dictionary.getPhrase(GAME_ENDED));
	}

    public function new() 
    {
        super();
        instance = this;

        drawChanges();
    }

    //TODO: The approach to changelog should be reconsidered during the UI update
    private function drawChanges() 
    {
        changes = new Label();
		changes.htmlText = Changes.getFormatted();
		changes.width = 300;
		changes.x = 15;
		changes.y = 10;
    }
}