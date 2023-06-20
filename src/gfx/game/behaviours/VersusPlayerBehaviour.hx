package gfx.game.behaviours;

import net.shared.utils.UnixTimestamp;
import gfx.game.behaviours.util.GameboardEventHandler;
import net.shared.board.RawPly;
import net.shared.dataobj.OfferDirection;
import net.shared.dataobj.OfferAction;
import net.shared.dataobj.OfferKind;
import net.shared.PieceColor;
import net.shared.dataobj.TimeReservesData;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.events.GameboardEvent;
import gfx.game.models.MatchVersusPlayerModel;
import net.Networker;

abstract class VersusPlayerBehaviour extends OwnGameBehaviour
{
    private var versusPlayerModel:MatchVersusPlayerModel;

    private abstract function onInvalidMove():Void;
    private abstract function onMoveAccepted(timestamp:UnixTimestamp):Void;
    private abstract function updateBehaviourDueToTurnColorUpdate():Void;
    private abstract function updateBehaviourDueToPremovePreferenceUpdate():Void;

    private function setPlayerOnlineStatus(playerColor:PieceColor, online:Bool)
    {
        if (playerColor != versusPlayerModel.getPlayerColor())
            versusPlayerModel.opponentOnline = online;
    }

    private function updateOfferStateDueToAction(offerSentBy:PieceColor, offer:OfferKind, action:OfferAction)
    {
        var direction:OfferDirection = offerSentBy == versusPlayerModel.getPlayerColor()? Outgoing : Incoming;
        var active:Bool = action.match(Create);
        versusPlayerModel.offerActive[offer][direction] = active;
        modelUpdateHandler(OfferStateUpdated(offer, direction, active));
    }

    private function onOfferActionRequested(kind:OfferKind, action:OfferAction)
    {
        var playerColor:PieceColor = versusPlayerModel.getPlayerColor();

        var active:Bool = action.match(Create);
        var direction:OfferDirection = action.match(Create | Cancel)? Outgoing : Incoming;
        var offerSentBy:PieceColor = direction.match(Outgoing)? playerColor : opposite(playerColor);

        Networker.emitEvent(PerformOfferAction(kind, action));

        versusPlayerModel.offerActive[kind][direction] = active;
        modelUpdateHandler(OfferStateUpdated(kind, direction, active));

        writeChatEntry(Log(OFFER_ACTION_MESSAGE(kind, offerSentBy, action)));
    }

    private function getPlannedPremoves():Array<RawPly>
    {
        return versusPlayerModel.plannedPremoves;
    }

    private function setPlannedPremoves(v:Array<RawPly>)
    {
        versusPlayerModel.plannedPremoves = v;
    }

    private function onCustomInitEnded():Void
    {
        //* Do nothing
    }

    public function new(versusPlayerModel:MatchVersusPlayerModel, performPremoveOnEntered:Bool, gameboardEventHandler:GameboardEventHandler)
    {
        super(versusPlayerModel, performPremoveOnEntered, gameboardEventHandler);
        this.versusPlayerModel = versusPlayerModel;
    }
}