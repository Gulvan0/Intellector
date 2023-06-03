package gfx.game.behaviours;

import gfx.game.models.MatchVersusBotModel;

class WaitingBotNoPremoves extends WaitingBotBehaviour 
{
    private function updateBehaviourDueToPremovePreferenceUpdate()
    {
        if (Preferences.premoveEnabled.get())
            screenRef.changeBehaviour(new WaitingBotPremoveable(versusBotModel));
    }

    public function new(versusBotModel:MatchVersusBotModel)
    {
        super(versusBotModel, None);
    }    
}