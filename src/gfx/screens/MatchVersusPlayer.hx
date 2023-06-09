package gfx.screens;

import assets.Audio;
import gfx.game.common.PanelName;
import gfx.game.common.ComponentPageName;
import gfx.game.behaviours.WaitingPlayerNoPremoves;
import gfx.game.behaviours.WaitingPlayerPremoveable;
import gfx.game.behaviours.MoveSelectVsPlayer;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.MatchVersusPlayerModel;
import dict.Phrase;
import net.shared.dataobj.ViewedScreen;
import gfx.game.models.ReadOnlyModel;
import gfx.game.events.ModelUpdateEvent;

class MatchVersusPlayer extends GenericGameScreen 
{
    private var model:MatchVersusPlayerModel;

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
        Audio.playSound("notify");
    }

	private function customOnClose() 
    {
        //* Do nothing
    }

	private function getModel():ReadOnlyModel 
    {
		return MatchVersusPlayer(model);
	}

	private function processModelUpdateAtTopLevel(update:ModelUpdateEvent) 
    {
        //* Do nothing
    }

    public function new(model:MatchVersusPlayerModel)
    {
        super();
        this.model = model;

        var isPlayerMove:Bool = model.getMostRecentSituation().turnColor == model.getPlayerColor();
        var initialBehaviour:IBehaviour;
        if (isPlayerMove)
            initialBehaviour = new MoveSelectVsPlayer(model)
        else if (Preferences.premoveEnabled.get())
            initialBehaviour = new WaitingPlayerPremoveable(model)
        else
            initialBehaviour = new WaitingPlayerNoPremoves(model);

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
