package gfx.game.behaviours;

import net.shared.PieceColor;
import gfx.game.models.MatchVersusPlayerModel;
import net.shared.dataobj.TimeReservesData;

class MoveSelectVsPlayer extends VersusPlayerBehaviour
{
    private function onInvalidMove()
    {
        Dialogs.alert(INVALID_MOVE_DIALOG_MESSAGE, INVALID_MOVE_DIALOG_TITLE);
    }

    private function onMoveAccepted(timeData:Null<TimeReservesData>)
    {
        throw "Unexpected onMoveAccepted call: should have happened in WaitingPlayerBehaviour";
    }

    private function updateBehaviourDueToTurnColorUpdate()
    {
        var turnColor:PieceColor = versusPlayerModel.getMostRecentSituation().turnColor;

        if (versusPlayerModel.getPlayerColor() != turnColor)
            if (Preferences.premoveEnabled.get())
                screenRef.changeBehaviour(new WaitingPlayerPremoveable(versusPlayerModel));
            else
                screenRef.changeBehaviour(new WaitingPlayerNoPremoves(versusPlayerModel));
    }

    private function updateBehaviourDueToPremovePreferenceUpdate()
    {
        //* Do nothing
    }

    public function new(versusPlayerModel:MatchVersusPlayerModel)
    {
        super(versusPlayerModel, true, Move);
    }
}