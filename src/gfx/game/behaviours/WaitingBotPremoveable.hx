package gfx.game.behaviours;

import gfx.game.models.MatchVersusBotModel;

class WaitingBotPremoveable extends WaitingBotBehaviour 
{
    private function updateBehaviourDueToPremovePreferenceUpdate()
    {
        if (!Preferences.premoveEnabled.get()) 
            screenRef.changeBehaviour(new WaitingBotNoPremoves(versusBotModel));
    }

    public function new(versusBotModel:MatchVersusBotModel)
    {
        super(versusBotModel, Premove);
    } 
}