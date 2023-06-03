package gfx.game.behaviours;

import net.shared.PieceColor;
import gfx.game.models.MatchVersusPlayerModel;
import net.shared.utils.UnixTimestamp;
import net.shared.PieceType;
import gfx.popups.PromotionSelect;
import net.shared.board.Situation;
import net.shared.board.Rules;
import net.shared.board.RawPly;
import net.shared.dataobj.TimeReservesData;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.events.GameboardEvent;

class MoveSelectVsPlayer extends VersusPlayerBehaviour
{
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
    }

    public function handleGameboardEvent(event:GameboardEvent)
    {
        switch event 
        {
            case MoveAttempted(from, to, options):
                var situation:Situation = versusPlayerModel.getMostRecentSituation();
                if (Rules.isChameleonAvailable(from, to, situation))
                {
                    var chameleonPly:RawPly = RawPly.chameleon(from, to, situation);
                    var normalPly:RawPly = RawPly.construct(from, to);

                    switch options.fastChameleon 
                    {
                        case AutoAccept:
                            performPly(chameleonPly);
                        case AutoDecline:
                            performPly(normalPly);
                        case Ask:
                            Dialogs.confirm(CHAMELEON_DIALOG_QUESTION, CHAMELEON_DIALOG_TITLE, performPly.bind(chameleonPly), performPly.bind(normalPly));
                    }
                }
                else if (Rules.isPromotionAvailable(from, to, situation))
                {
                    switch options.fastPromotion 
                    {
                        case AutoPromoteToDominator:
                            performPly(RawPly.construct(from, to, Dominator));
                        case Ask:
                            var onPieceSelected:PieceType->Void = type -> {
                                performPly(RawPly.construct(from, to, type));
                            }
                            var dialog:PromotionSelect = new PromotionSelect(versusPlayerModel.getPlayerColor(), onPieceSelected);
                            Dialogs.getQueue().add(dialog);
                    }
                }
                else
                    performPly(RawPly.construct(from, to));
            default:
        }
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        //* Do nothing
    }

    private function onInvalidMove()
    {
        Dialogs.alert(INVALID_MOVE_DIALOG_MESSAGE, INVALID_MOVE_DIALOG_TITLE);
    }

    private function onMoveAccepted(timeData:Null<TimeReservesData>)
    {
        throw "Unexpected onMoveAccepted call: should have happened in WaitingPlayerBehaviour";
    }

    private function customOnEntered()
    {
        if (!Lambda.empty(versusPlayerModel.plannedPremoves))
        {
            var plannedPremove:RawPly = versusPlayerModel.plannedPremoves.shift();

            if (Rules.isPossible(plannedPremove, model.getMostRecentSituation()))
                performPly(plannedPremove);
            else
                versusPlayerModel.plannedPremoves = [];

            modelUpdateHandler(PlannedPremovesUpdated);
        }
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

    public function new(versusPlayerModel:MatchVersusPlayerModel)
    {
        super(versusPlayerModel);
    }
}