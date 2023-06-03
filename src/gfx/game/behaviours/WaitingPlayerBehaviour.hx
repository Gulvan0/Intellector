package gfx.game.behaviours;

import gfx.game.behaviours.util.GameboardEventHandler;
import gfx.game.models.MatchVersusPlayerModel;
import net.shared.dataobj.TimeReservesData;
import net.shared.PieceColor;

abstract class WaitingPlayerBehaviour extends VersusPlayerBehaviour 
{
    private abstract function updateBehaviourDueToPremovePreferenceUpdate():Void;

    private function onInvalidMove()
    {
        Dialogs.alert(INVALID_MOVE_DIALOG_MESSAGE, INVALID_MOVE_DIALOG_TITLE);

        rollback(1, null);
    }

    private function onMoveAccepted(timeData:Null<TimeReservesData>)
    {
        if (timeData != null)
        {
            versusPlayerModel.perMoveTimeRemaindersData.modifyLast(timeData);
            modelUpdateHandler(TimeDataUpdated);
        }
    }

    private function updateBehaviourDueToTurnColorUpdate():Void
    {
        var turnColor:PieceColor = versusPlayerModel.getMostRecentSituation().turnColor;

        if (versusPlayerModel.getPlayerColor() == turnColor)
            screenRef.changeBehaviour(new MoveSelectVsPlayer(versusPlayerModel));
    }

    public function new(versusPlayerModel:MatchVersusPlayerModel, gameboardEventHandler:GameboardEventHandler)
    {
        super(versusPlayerModel, false, gameboardEventHandler);
    }
}