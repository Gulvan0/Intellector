package gfx.game.behaviours;

import gfx.game.models.MatchVersusPlayerModel;
import gfx.game.events.GameboardEvent;

class WaitingPlayerNoPremoves extends WaitingPlayerBehaviour
{
    public function handleGameboardEvent(event:GameboardEvent)
    {
        //* Do nothing
    }

    private function updateBehaviourDueToPremovePreferenceUpdate()
    {
        if (Preferences.premoveEnabled.get())
            screenRef.changeBehaviour(new WaitingPlayerPremoveable(versusPlayerModel));
    }

    public function new(versusPlayerModel:MatchVersusPlayerModel)
    {
        super(versusPlayerModel);
    }
}