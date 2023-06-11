package gfx.game.behaviours;

import gfx.game.interfaces.IReadWriteGameRelatedModel;
import gfx.game.events.util.MoveIntentOptions;
import net.shared.board.HexCoords;
import gfx.popups.PromotionSelect;
import net.shared.PieceType;
import gfx.game.behaviours.util.GameboardEventHandler;
import net.shared.board.Rules;
import net.shared.board.Situation;
import net.shared.utils.UnixTimestamp;
import net.shared.board.RawPly;
import net.shared.dataobj.OfferAction;
import net.shared.dataobj.OfferKind;
import net.shared.PieceColor;
import net.shared.dataobj.TimeReservesData;
import gfx.game.events.GameboardEvent;
import GlobalBroadcaster.GlobalEvent;

abstract class OwnGameBehaviour extends GameRelatedBehaviour
{
    private var performPremoveOnEntered:Bool;
    private var gameboardEventHandler:GameboardEventHandler;

    private abstract function onInvalidMove():Void;
    private abstract function onMoveAccepted(timestamp:UnixTimestamp):Void;
    private abstract function setPlayerOnlineStatus(playerColor:PieceColor, online:Bool):Void;
    private abstract function updateOfferStateDueToAction(offerSentBy:PieceColor, offer:OfferKind, action:OfferAction):Void;
    private abstract function onOfferActionRequested(kind:OfferKind, action:OfferAction):Void;
    private abstract function updateBehaviourDueToTurnColorUpdate():Void;
    private abstract function getPlannedPremoves():Array<RawPly>;
    private abstract function setPlannedPremoves(v:Array<RawPly>):Void;
    private abstract function updateBehaviourDueToPremovePreferenceUpdate():Void;
    private abstract function onCustomInitEnded():Void;

    private function onScrolledToPastMove()
    {
        setPlannedPremoves([]);
        modelUpdateHandler(PlannedPremovesUpdated);

        model.deriveShownSituationFromOtherParams();
        modelUpdateHandler(ShownSituationUpdated);
    }

    private function performPly(ply:RawPly)
    {
        Networker.emitEvent(Move(ply));

        model.history.append(ply);
        modelUpdateHandler(MoveAddedToHistory);

        var newMoveCount:Int = model.getLineLength();

        model.shownMovePointer = newMoveCount;
        modelUpdateHandler(ViewedMoveNumUpdated);

        model.deriveShownSituationFromOtherParams();
        modelUpdateHandler(ShownSituationUpdated);

        if (!model.timeControl.isCorrespondence())
        {
            var nowTimestamp:UnixTimestamp = UnixTimestamp.now();
            model.perMoveTimeRemaindersData.onMoveMade(nowTimestamp);
            modelUpdateHandler(TimeDataUpdated);
        }

        updateBehaviourDueToTurnColorUpdate();
    }

    private function appendPremove(ply:RawPly)
    {
        var premoves:Array<RawPly> = getPlannedPremoves();
        premoves.push(ply);
        setPlannedPremoves(premoves);
        modelUpdateHandler(PlannedPremovesUpdated);

        model.deriveShownSituationFromOtherParams();
        modelUpdateHandler(ShownSituationUpdated);
    }
    
    public function handleGameboardEvent(event:GameboardEvent)
    {
        switch event 
        {
            case MoveAttempted(from, to, options):
                switch gameboardEventHandler 
                {
                    case Move:
                        constructMove(from, to, options, false, performPly);
                    case Premove:
                        constructMove(from, to, options, true, appendPremove);
                    case None:
                        return;
                }
            case LMBPressed(hexUnderCursor):
                applyScroll(End);

                if (model.getShownSituation().get(hexUnderCursor).color() != model.getPlayerColor())
                {
                    setPlannedPremoves([]);
                    modelUpdateHandler(PlannedPremovesUpdated);

                    model.deriveShownSituationFromOtherParams();
                    modelUpdateHandler(ShownSituationUpdated);
                }
            default:
        }
    }

    private function customOnEntered()
    {
        var plannedPremoves:Array<RawPly> = getPlannedPremoves();
        if (!Lambda.empty(plannedPremoves))
        {
            var plannedPremove:RawPly = plannedPremoves.shift();
            var performPlannedPremove:Bool = performPremoveOnEntered && Rules.isPossible(plannedPremove, model.getMostRecentSituation());

            if (!performPlannedPremove)
                plannedPremoves = [];

            setPlannedPremoves(plannedPremoves);
            modelUpdateHandler(PlannedPremovesUpdated);

            if (performPlannedPremove)
            {
                performPly(plannedPremove);
                return;
            }
        }
        
        onCustomInitEnded();
        
        model.deriveShownSituationFromOtherParams();
        modelUpdateHandler(ShownSituationUpdated);
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

    private function isAutoscrollEnabled():Bool
    {
        return Preferences.autoScrollOnMove.get().match(Always | OwnGameOnly);
    }

    public function new(model:IReadWriteGameRelatedModel, performPremoveOnEntered:Bool, gameboardEventHandler:GameboardEventHandler)
    {
        super(model);
        this.performPremoveOnEntered = performPremoveOnEntered;
        this.gameboardEventHandler = gameboardEventHandler;
    }
}