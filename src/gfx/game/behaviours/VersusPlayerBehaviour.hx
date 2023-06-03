package gfx.game.behaviours;

import net.shared.dataobj.OfferDirection;
import net.shared.dataobj.OfferAction;
import net.shared.dataobj.OfferKind;
import net.shared.PieceColor;
import net.shared.dataobj.TimeReservesData;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.events.GameboardEvent;
import gfx.game.models.MatchVersusPlayerModel;

abstract class VersusPlayerBehaviour extends GameRelatedBehaviour
{
    private var versusPlayerModel:MatchVersusPlayerModel;

    public abstract function handleGameboardEvent(event:GameboardEvent):Void;
    public abstract function handleGlobalEvent(event:GlobalEvent):Void;
    private abstract function onInvalidMove():Void;
    private abstract function onMoveAccepted(timeData:Null<TimeReservesData>):Void;
    private abstract function customOnEntered():Void;
    private abstract function updateBehaviourDueToTurnColorUpdate():Void;

    private function setPlayerOnlineStatus(playerColor:PieceColor, online:Bool)
    {
        if (playerColor != versusPlayerModel.getPlayerColor())
            versusPlayerModel.opponentOnline = online;
    }

    private function isAutoscrollEnabled():Bool
    {
        return Preferences.autoScrollOnMove.get().match(Always | OwnGameOnly);
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

    public function new(versusPlayerModel:MatchVersusPlayerModel)
    {
        super(versusPlayerModel);
        this.versusPlayerModel = versusPlayerModel;
    }
}