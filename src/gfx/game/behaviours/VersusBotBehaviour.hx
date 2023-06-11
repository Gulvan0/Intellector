package gfx.game.behaviours;

import net.shared.board.RawPly;
import gfx.game.behaviours.util.GameboardEventHandler;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.events.GameboardEvent;
import net.shared.dataobj.TimeReservesData;
import net.shared.PieceColor;
import net.shared.utils.UnixTimestamp;
import gfx.game.models.MatchVersusBotModel;
import net.shared.dataobj.OfferAction;
import net.shared.dataobj.OfferKind;

abstract class VersusBotBehaviour extends OwnGameBehaviour
{
    private var versusBotModel:MatchVersusBotModel;

    private abstract function updateBehaviourDueToTurnColorUpdate():Void;
    private abstract function updateBehaviourDueToPremovePreferenceUpdate():Void;
    private abstract function onCustomInitEnded():Void;

    private function setPlayerOnlineStatus(playerColor:PieceColor, online:Bool)
    {
        //* Do nothing
    }

    private function onOfferActionRequested(kind:OfferKind, action:OfferAction)
    {
        if (!action.match(Create) || !kind.match(Takeback))
            throw 'Create/Takeback is the only offer action available in matches versus bot. Got: ${action}/${kind}';

        versusBotModel.opponentBot.interrupt();

        var plysToUndo:Int = versusBotModel.getPlayerColor() == versusBotModel.getMostRecentSituation().turnColor? 2 : 1;
        var timestamp:UnixTimestamp = UnixTimestamp.now();
        rollback(plysToUndo, timestamp);
        Networker.emitEvent(BotGameRollback(plysToUndo, timestamp));
    }

    private function updateOfferStateDueToAction(offerSentBy:PieceColor, offer:OfferKind, action:OfferAction)
    {
        //* Do nothing
    }

    private function onInvalidMove()
    {
        //* Do nothing
    }

    private function onMoveAccepted(timestamp:UnixTimestamp)
    {
        //* Do nothing
    }

    private function getPlannedPremoves():Array<RawPly>
    {
        return versusBotModel.plannedPremoves;
    }

    private function setPlannedPremoves(v:Array<RawPly>)
    {
        versusBotModel.plannedPremoves = v;
    }

    public function new(versusBotModel:MatchVersusBotModel, performPremoveOnEntered:Bool, gameboardEventHandler:GameboardEventHandler)
    {
        super(versusBotModel, performPremoveOnEntered, gameboardEventHandler);
        this.versusBotModel = versusBotModel;
    }
}