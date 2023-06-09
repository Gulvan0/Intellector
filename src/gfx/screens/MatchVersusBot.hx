package gfx.screens;

import browser.Blinker;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.models.ReadOnlyModel;
import assets.Audio;
import dict.Phrase;
import net.shared.dataobj.ViewedScreen;
import gfx.game.common.ComponentPageName;
import gfx.game.common.PanelName;
import gfx.game.interfaces.IBehaviour;
import gfx.game.behaviours.WaitingBotNoPremoves;
import gfx.game.behaviours.WaitingBotPremoveable;
import gfx.game.behaviours.MoveSelectVsBot;
import gfx.game.models.MatchVersusBotModel;

class MatchVersusBot extends GenericGameScreen
{
    private var model:MatchVersusBotModel;

	public function getTitle():Null<Phrase> 
    {
		return OWN_MATCH_SCREEN_TITLE(model.getOpponentRef());
	}

	public function getURLPath():Null<String> 
    {
		return 'live/${model.gameID}';
	}

	public function getPage():ViewedScreen 
    {
		return Game(model.gameID);
	}

	private function customOnEnter() 
    {
        FollowManager.stopFollowing();
        Dialogs.getQueue().closeGroup(RemovedOnGameStarted);
        Blinker.blink(GameStarted);
        if (!model.timeControl.isCorrespondence())
            GlobalBroadcaster.broadcast(LockedInGame);
        Audio.playSound("notify");
    }

	private function customOnClose() 
    {
        model.opponentBot.interrupt();
    }

	private function getModel():ReadOnlyModel 
    {
		return MatchVersusBot(model);
	}

	private function processModelUpdateAtTopLevel(update:ModelUpdateEvent) 
    {
        switch update 
        {
            case GameEnded:
                if (!model.timeControl.isCorrespondence())
                    GlobalBroadcaster.broadcast(NotLockedInGame);
            default:
        }
    }

    public function new(model:MatchVersusBotModel)
    {
        super();
        this.model = model;

        var isPlayerMove:Bool = model.getMostRecentSituation().turnColor == model.getPlayerColor();
        var initialBehaviour:IBehaviour;
        if (isPlayerMove)
            initialBehaviour = new MoveSelectVsBot(model);
        else if (Preferences.premoveEnabled.get())
            initialBehaviour = new WaitingBotPremoveable(model);
        else
            initialBehaviour = new WaitingBotNoPremoves(model);

        var panelMap:Map<PanelName, Array<ComponentPageName>> = [
            LargeBoardBox => [Board],
            LargeExtras => [],
            LargeLeft => [LargeLeftPanelMain],
            LargeRight => [UCMA],
            CompactBoardBox => [BoardAndClocks],
            CompactExtras => [],
            CompactTop => [CreepingLine],
            CompactBottom => [CompactLiveActionBar]
        ];

        var subscreenNames:Array<ComponentPageName> = [Chat, GameInfoSubscreen, SpecialControlSettings];

        init(initialBehaviour, panelMap, subscreenNames);
    }
}