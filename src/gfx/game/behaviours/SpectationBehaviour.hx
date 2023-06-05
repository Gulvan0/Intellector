package gfx.game.behaviours;

import net.shared.dataobj.OfferAction;
import net.shared.dataobj.OfferKind;
import net.shared.PieceColor;
import gfx.game.events.GameboardEvent;
import GlobalBroadcaster.GlobalEvent;
import net.shared.dataobj.TimeReservesData;
import gfx.game.models.SpectationModel;

class SpectationBehaviour extends GameRelatedBehaviour
{
    private var spectationModel:SpectationModel;

    private function onScrolledToPastMove()
    {
        //* Do nothing
    }

    private function setPlayerOnlineStatus(playerColor:PieceColor, online:Bool)
    {
        spectationModel.playerOnline.set(playerColor, online);
    }

    private function updateOfferStateDueToAction(offerSentBy:PieceColor, offer:OfferKind, action:OfferAction)
    {
        var active:Bool = action.match(Create);
        spectationModel.outgoingOfferActive[offerSentBy].set(offer, active);
    }

    private function onOfferActionRequested(kind:OfferKind, action:OfferAction)
    {
        trace('Unexpected offer action (${action}/${kind}) for SpectatorBehaviour');
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        //* Do nothing
    }

    public function handleGameboardEvent(event:GameboardEvent)
    {
        //* Do nothing
    }

    private function customOnEntered()
    {
        //* Do nothing
    }

    private function onInvalidMove()
    {
        trace("Unexpected InvalidMove for SpectatorBehaviour");
    }

    private function onMoveAccepted(timeData:Null<TimeReservesData>)
    {
        trace("Unexpected MoveAccepted for SpectatorBehaviour");
    }

    private function updateBehaviourDueToTurnColorUpdate()
    {
        //* Do nothing
    }

    private function isAutoscrollEnabled():Bool
    {
        return Preferences.autoScrollOnMove.get().match(Always);
    }

    public function new(spectationModel:SpectationModel)
    {
        super(spectationModel);
        this.spectationModel = spectationModel;
    }
}