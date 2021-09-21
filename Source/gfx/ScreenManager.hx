package gfx;

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
import Networker.BattleData;
import Networker.OpenChallengeData;
import Networker.OngoingBattleData;
import Networker.GameOverData;
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

    public function toGameStart(data:BattleData) 
    {
        var isGuest = Networker.login.startsWith("guest_");
        var onReturnPressed = isGuest? Networker.dropConnection : toMain;
        toGameGeneric(data.match_id, GameCompound.buildActive(data, onReturnPressed));
    }

    public function toGameReconnect(data:OngoingBattleData) 
    {
        var isGuest = Networker.login.startsWith("guest_");
        var onReturnPressed = isGuest? Networker.dropConnection : toMain;
        toGameGeneric(data.match_id, GameCompound.buildActiveReconnect(data, onReturnPressed));
    }

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

    public function toOpenChallengeJoiningRoom(data:OpenChallengeData) 
    {
        clear();
        URLEditor.clear();
        
        current = new OpenChallengeJoining(data);
        addChild(current);
    }

    public function toAnalysisBoard() 
    {
        clear();
        URLEditor.clear();
        
        current = GameCompound.buildAnalysis(() ->
        {
            Networker.currentGameCompound = null;
		    toMain();
        });
        addChild(current);
    }

    public function toSpectation(data:OngoingBattleData) 
	{
		clear();
        URLEditor.assignID(data.match_id);

        var game = GameCompound.buildSpectators(data, () -> 
        {
            Networker.stopSpectation(); 
            Networker.currentGameCompound = null;
		    toMain();
        });
        
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
    
    public function toRevisit(id:Int, log:String) 
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
            startSecs: null,
            bonusSecs: null, 
            whiteSeconds: null, 
            blackSeconds: null, 
            position: null,
            currentLog: log
        };

        current = GameCompound.buildSpectators(mockData, toMain, true);
        addChild(current);
    }

    public function toProfile(login:String, gamesList:String) 
    {
        clear();
        URLEditor.assignProfileLogin(login);

        current = new PlayerProfile(login, gamesList);
        addChild(current);
    }

    public function toSettings() 
    {
        clear();
        URLEditor.clear();
        
        current = new Settings();
        addChild(current);
    }
    
    private function onGameEnded(data:GameOverData) 
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

    private function drawChanges() 
    {
        changes = new Label();
		changes.htmlText = Changes.getFormatted();
		changes.width = 300;
		changes.x = 15;
		changes.y = 10;
    }
}