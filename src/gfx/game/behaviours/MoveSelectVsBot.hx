package gfx.game.behaviours;

import net.shared.PieceColor;
import gfx.game.models.MatchVersusBotModel;

class MoveSelectVsBot extends VersusBotBehaviour 
{
    private function updateBehaviourDueToPremovePreferenceUpdate()
    {
        //* Do nothing
    }

    private function updateBehaviourDueToTurnColorUpdate()
    {
        var turnColor:PieceColor = versusBotModel.getMostRecentSituation().turnColor;

        if (versusBotModel.getPlayerColor() != turnColor)
            if (Preferences.premoveEnabled.get())
                screenRef.changeBehaviour(new WaitingBotPremoveable(versusBotModel));
            else
                screenRef.changeBehaviour(new WaitingBotNoPremoves(versusBotModel));
    }

    private function onCustomInitEnded():Void
    {
        //* Do nothing
    }

    public function new(versusBotModel:MatchVersusBotModel)
    {
        super(versusBotModel, true, Move);
    }    
}