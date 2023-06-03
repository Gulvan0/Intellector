package gfx.game.behaviours;

import gfx.game.models.MatchVersusPlayerModel;
import net.shared.dataobj.TimeReservesData;
import net.shared.PieceColor;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.events.GameboardEvent;

abstract class WaitingPlayerBehaviour extends VersusPlayerBehaviour 
{
    public abstract function handleGameboardEvent(event:GameboardEvent):Void;
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

    private function customOnEntered()
    {
        if (!Lambda.empty(versusPlayerModel.plannedPremoves))
        {
            versusPlayerModel.plannedPremoves = [];
            modelUpdateHandler(PlannedPremovesUpdated);
        }
    }

    private function updateBehaviourDueToTurnColorUpdate():Void
    {
        var turnColor:PieceColor = versusPlayerModel.getMostRecentSituation().turnColor;

        if (versusPlayerModel.getPlayerColor() == turnColor)
            screenRef.changeBehaviour(new MoveSelectVsPlayer(versusPlayerModel));
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case PreferenceUpdated(Premoves):
                updateBehaviourDueToPremovePreferenceUpdate();
            default:
        }
    }

    public function new(versusPlayerModel:MatchVersusPlayerModel)
    {
        super(versusPlayerModel);
    }
}