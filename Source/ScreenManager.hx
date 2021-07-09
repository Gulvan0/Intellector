package;

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
        Networker.registerMainMenuEvents();
        
        current = new MainMenu();
        addChild(current);
        addChild(changes);
    }

    public function toGameStart(data:BattleData) 
    {
        toGameGeneric(data.match_id, GameCompound.buildActive(data));
    }

    public function toGameReconnect(data:OngoingBattleData) 
    {
        toGameGeneric(data.match_id, GameCompound.buildActiveReconnect(data));
    }

    private function toGameGeneric(id:Int, game:GameCompound) 
    {
        clear();
        URLEditor.assignID(id);

        current = game;
		Networker.currentGameCompound = game;
		Networker.registerGameEvents(onGameEnded);

        addChild(current);
		Assets.getSound("sounds/notify.mp3").play();
    }

    public function toOpenChallengeHostingRoom(startSecs:Int, bonusSecs:Int) 
    {
        clear();
        URLEditor.clear();
        
        current = new OpenChallengeHosting(startSecs, bonusSecs);
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
        
        current = GameCompound.buildAnalysis(onReturn);
        addChild(current);
    }

    public function toSpectation(data:OngoingBattleData) 
	{
		clear();
        URLEditor.assignID(data.match_id);

        var game = GameCompound.buildSpectators(data, () -> 
        {
            Networker.stopSpectate(); 
            onReturn();
        });
        
		current = game;
		Networker.currentGameCompound = game;
        addChild(current);
	}

    public function toSettings() 
    {
        clear();
        URLEditor.clear();
        
        current = new Settings();
        addChild(current);
    }

    private function onReturn() 
    {
        Networker.currentGameCompound = null;
		toMain();
    }
    
    private function onGameEnded(data:GameOverData) 
	{
        var playerColor:String = Networker.currentGameCompound.playerColor.getName().toLowerCase();
		Networker.currentGameCompound.terminate();
		Networker.currentGameCompound = null;

		var resultMessage;
		if (data.winner_color == "")
			resultMessage = "½ - ½";
		else if (data.winner_color == playerColor)
			resultMessage = Dictionary.getPhrase(WIN_MESSAGE_PREAMBLE);
		else 
			resultMessage = Dictionary.getPhrase(LOSS_MESSAGE_PREAMBLE);

		var explanation = Dictionary.getGameOverExplanation(data.reason);

		Assets.getSound("sounds/notify.mp3").play();
		Dialogs.info(Dictionary.getPhrase(GAME_OVER) + resultMessage + explanation, Dictionary.getPhrase(GAME_ENDED));

		ScreenManager.instance.toEmpty();
		if (Networker.login.startsWith("guest_"))
			Networker.dropConnection();
		else
			ScreenManager.instance.toMain();
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