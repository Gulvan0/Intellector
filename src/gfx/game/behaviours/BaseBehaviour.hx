package gfx.game.behaviours;

import gfx.popups.PromotionSelect;
import net.shared.PieceType;
import net.shared.board.RawPly;
import gfx.game.events.util.MoveIntentOptions;
import net.shared.board.HexCoords;
import net.shared.board.Situation;
import net.shared.board.Rules;
import net.shared.PieceColor.opposite;
import net.shared.ServerEvent;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.events.GameboardEvent;
import gfx.game.events.ChatboxEvent;
import gfx.game.events.PlyHistoryViewEvent;
import gfx.game.events.VariationViewEvent;
import gfx.game.events.PositionEditorEvent;
import gfx.utils.PlyScrollType;
import gfx.game.events.ActionBarEvent;
import gfx.popups.ChallengeParamsDialog;
import net.shared.dataobj.ChallengeParams;
import gfx.game.common.action_bar.ActionButton;
import net.shared.dataobj.OfferAction;
import net.shared.dataobj.OfferKind;
import gfx.game.interfaces.IGameScreen;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.interfaces.IReadWriteGenericModel;
import gfx.game.interfaces.IBehaviour;

abstract class BaseBehaviour implements IBehaviour
{
    private var genericModel:IReadWriteGenericModel;
    private var modelUpdateHandler:ModelUpdateEvent->Void;
    private var screenRef:IGameScreen;

    public abstract function handleNetEvent(event:ServerEvent):Void;
    public abstract function handleGlobalEvent(event:GlobalEvent):Void;
    public abstract function handleGameboardEvent(event:GameboardEvent):Void;
    public abstract function handleChatboxEvent(event:ChatboxEvent):Void; 
	public abstract function handleVariationViewEvent(event:VariationViewEvent):Void;
	public abstract function handlePositionEditorEvent(event:PositionEditorEvent):Void;
    private abstract function customOnEntered():Void;
    private abstract function onResignPressed():Void;
    private abstract function onAbortPressed():Void;
    private abstract function onSharePressed():Void;
    private abstract function onOfferActionRequested(kind:OfferKind, action:OfferAction):Void;
    private abstract function onAddTimePressed():Void;
    private abstract function onRematchPressed():Void;
    private abstract function onAnalyzePressed():Void;
    private abstract function onEditPositionPressed():Void;
    private abstract function onViewReportPressed():Void;

    private function applyScroll(type:PlyScrollType)
    {
        switch type 
        {
            case Home:
                if (genericModel.shownMovePointer == 0)
                    return;
                genericModel.shownMovePointer = 0;
            case Prev:
                if (genericModel.shownMovePointer == 0)
                    return;
                genericModel.shownMovePointer--;
            case Next:
                var moveCount:Int = genericModel.getLineLength();
                if (genericModel.shownMovePointer == moveCount)
                    return;
                genericModel.shownMovePointer++;
            case End:
                var moveCount:Int = genericModel.getLineLength();
                if (genericModel.shownMovePointer == moveCount)
                    return;
                genericModel.shownMovePointer = moveCount;
            case Precise(plyNum):
                if (genericModel.shownMovePointer == plyNum)
                    return;
                genericModel.shownMovePointer = plyNum;
        }

        modelUpdateHandler(ViewedMoveNumUpdated);
    }

    private function constructMove(from:HexCoords, to:HexCoords, options:MoveIntentOptions, premove:Bool, onMoveConstructed:RawPly->Void)
    {
        var situation:Situation = genericModel.getShownSituation();
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
                    var dialog:PromotionSelect = new PromotionSelect(situation.get(from).color(), onPieceSelected);
                    Dialogs.getQueue().add(dialog);
            }
        }
        else
            onMoveConstructed(RawPly.construct(from, to));
    }

    public function onEntered(modelUpdateHandler:ModelUpdateEvent->Void, screenRef:IGameScreen)
    {
        this.modelUpdateHandler = modelUpdateHandler;
        this.screenRef = screenRef;

        customOnEntered();

        genericModel.deriveInteractivityModeFromOtherParams();
        modelUpdateHandler(InteractivityModeUpdated);
    }

    private function handleActionButtonPress(btn:ActionButton)
    {
        switch btn.unwrap() 
        {
            case Resign:
                onResignPressed();
            case Abort:
                onAbortPressed();
            case OfferDraw:
                onOfferActionRequested(Draw, Create);
            case CancelDraw:
                onOfferActionRequested(Draw, Cancel);
            case OfferTakeback:
                onOfferActionRequested(Takeback, Create);
            case CancelTakeback:
                onOfferActionRequested(Takeback, Cancel);
            case AddTime:
                onAddTimePressed();
            case Rematch:
                onRematchPressed();
            case Analyze:
                onAnalyzePressed();
            case ChangeOrientation:
                genericModel.orientation = opposite(genericModel.orientation);
                modelUpdateHandler(OrientationUpdated);
            case Share:
                onSharePressed();
            case PlayFromHere:
                var params:ChallengeParams = ChallengeParams.playFromPosParams(genericModel.getShownSituation());
                Dialogs.getQueue().add(new ChallengeParamsDialog(params, true));
            case PrevMove:
                applyScroll(Prev);
            case NextMove:
                applyScroll(Next);
            case EditPosition:
                onEditPositionPressed();
            case ViewReport:
                onViewReportPressed();
            case OpenChat:
                screenRef.displaySubscreen(Chat);
            case OpenBranching:
                screenRef.displaySubscreen(Branching);
            case OpenSpecialControlSettings:
                screenRef.displaySubscreen(SpecialControlSettings);
            case OpenGameInfo:
                screenRef.displaySubscreen(GameInfoSubscreen);
        }
    }

	public function handleActionBarEvent(event:ActionBarEvent) 
    {
        switch event 
        {
            case ActionButtonPressed(btn):
                handleActionButtonPress(btn);
            case IncomingOfferAccepted(kind):
                onOfferActionRequested(kind, Accept);
            case IncomingOfferDeclined(kind):
                onOfferActionRequested(kind, Decline);
        }
    }

	public function handlePlyHistoryViewEvent(event:PlyHistoryViewEvent) 
    {
        switch event 
        {
            case ScrollRequested(type):
                applyScroll(type);
        }
    }

    public function new(genericModel:IReadWriteGenericModel)
    {
        this.genericModel = genericModel;
    }
}