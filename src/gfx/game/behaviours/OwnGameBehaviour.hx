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
    private abstract function onMoveAccepted(timeData:Null<TimeReservesData>):Void;
    private abstract function setPlayerOnlineStatus(playerColor:PieceColor, online:Bool):Void;
    private abstract function updateOfferStateDueToAction(offerSentBy:PieceColor, offer:OfferKind, action:OfferAction):Void;
    private abstract function onOfferActionRequested(kind:OfferKind, action:OfferAction):Void;
    private abstract function updateBehaviourDueToTurnColorUpdate():Void;
    private abstract function getPlannedPremoves():Array<RawPly>;
    private abstract function setPlannedPremoves(v:Array<RawPly>):Void;
    private abstract function updateBehaviourDueToPremovePreferenceUpdate():Void;
    private abstract function onCustomInitEnded():Void;

    private function performPly(ply:RawPly)
    {
        Networker.emitEvent(Move(ply));

        model.history.append(ply);
        modelUpdateHandler(MoveAddedToHistory);

        var newMoveCount:Int = model.getLineLength();

        model.shownMovePointer = newMoveCount;
        modelUpdateHandler(ViewedMoveNumUpdated);

        if (!model.timeControl.isCorrespondence())
        {
            var timeData:TimeReservesData = model.perMoveTimeRemaindersData.getTimeLeftAfterMove(newMoveCount - 1);
            var nowTimestamp:UnixTimestamp = UnixTimestamp.now();
            if (model.activeTimerColor != null)
            {
                var pastSeconds:Float = timeData.getSecsLeftAtTimestamp(model.activeTimerColor);
                var secondsPassed:Float = nowTimestamp.getIntervalSecsFrom(timeData.timestamp);
                var actualSeconds:Float = pastSeconds - secondsPassed;
                timeData.setSecsLeftAtTimestamp(model.activeTimerColor, actualSeconds);
            }
            model.perMoveTimeRemaindersData.append(timeData);
            deriveActiveTimerColor(newMoveCount);
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
    }

    private function onMoveAttempted(from:HexCoords, to:HexCoords, options:MoveIntentOptions, premove:Bool)
    {
        var onMoveConstructed:RawPly->Void = premove? appendPremove : performPly;

        var situation:Situation = premove? model.getShownSituation() : model.getMostRecentSituation();
        if (!premove && Rules.isChameleonAvailable(from, to, situation))
        {
            var chameleonPly:RawPly = RawPly.chameleon(from, to, situation);
            var normalPly:RawPly = RawPly.construct(from, to);

            switch options.fastChameleon 
            {
                case AutoAccept:
                    onMoveConstructed(chameleonPly);
                case AutoDecline:
                    onMoveConstructed(normalPly);
                case Ask:
                    Dialogs.confirm(CHAMELEON_DIALOG_QUESTION, CHAMELEON_DIALOG_TITLE, onMoveConstructed.bind(chameleonPly), onMoveConstructed.bind(normalPly));
            }
        }
        else if (Rules.isPromotionAvailable(from, to, situation))
        {
            switch options.fastPromotion 
            {
                case AutoPromoteToDominator:
                    onMoveConstructed(RawPly.construct(from, to, Dominator));
                case Ask:
                    var onPieceSelected:PieceType->Void = type -> {
                        onMoveConstructed(RawPly.construct(from, to, type));
                    }
                    var dialog:PromotionSelect = new PromotionSelect(model.getPlayerColor(), onPieceSelected);
                    Dialogs.getQueue().add(dialog);
            }
        }
        else
            onMoveConstructed(RawPly.construct(from, to));
    }
    
    public function handleGameboardEvent(event:GameboardEvent)
    {
        switch event 
        {
            case MoveAttempted(from, to, options):
                switch gameboardEventHandler 
                {
                    case Move:
                        onMoveAttempted(from, to, options, false);
                    case Premove:
                        onMoveAttempted(from, to, options, true);
                    case None:
                        return;
                }
            case LMBPressed(hexUnderCursor):
                applyScroll(End);
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