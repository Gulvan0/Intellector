package gfx.game.behaviours;

import gfx.game.models.MatchVersusPlayerModel;
import gfx.game.events.GameboardEvent;

class WaitingPlayerPremoveable extends WaitingPlayerBehaviour
{
    private function updateBehaviourDueToPremovePreferenceUpdate()
    {
        if (!Preferences.premoveEnabled.get()) 
            screenRef.changeBehaviour(new WaitingPlayerNoPremoves(versusPlayerModel));
    }

    public function new(versusPlayerModel:MatchVersusPlayerModel)
    {
        super(versusPlayerModel, Premove);
    }
}