package gfx.screens;

import dict.Phrase;
import net.shared.dataobj.ViewedScreen;
import assets.Audio;
import gfx.game.models.ReadOnlyModel;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.common.ComponentPageName;
import gfx.game.interfaces.IBehaviour;
import gfx.game.common.PanelName;
import gfx.game.behaviours.SpectationBehaviour;
import gfx.game.models.SpectationModel;

class Spectation extends GenericGameScreen 
{
    private var model:SpectationModel;

	public function getTitle():Null<Phrase> 
    {
        if (model.hasEnded())
		    return PAST_GAME_SCREEN_TITLE(model.gameID, model.getPlayerRef(White), model.getPlayerRef(Black));
        else
            return SPECTATING_SCREEN_TITLE(model.getPlayerRef(White), model.getPlayerRef(Black));
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
        FollowManager.followedGameID = model.gameID;
    }

	private function customOnClose() 
    {
        if (FollowManager.followedGameID == model.gameID)
            FollowManager.stopFollowing();
    }

	private function getModel():ReadOnlyModel 
    {
		return Spectation(model);
	}

	private function processModelUpdateAtTopLevel(update:ModelUpdateEvent) 
    {
        //* Do nothing
    }

    public function new(model:SpectationModel)
    {
        super();
        this.model = model;

        var initialBehaviour:IBehaviour = new SpectationBehaviour(model);

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