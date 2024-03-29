package gfx.game;

import net.shared.utils.PlayerRef;
import utils.TimeControl;
import assets.StandaloneAssetPath;
import haxe.Timer;
import net.shared.Constants;
import gameboard.GameBoard.IGameBoardObserver;
import net.EventProcessingQueue.INetObserver;
import gameboard.GameBoard.GameBoardEvent;
import haxe.ui.containers.VBox;
import net.shared.PieceColor;
import js.Browser;
import net.shared.ServerEvent;
import haxe.ui.components.Button;
import haxe.ui.containers.ButtonBar;
import dict.Dictionary;

enum Mode
{
    PlayerOngoingGame;
    PlayerOngoingVersusBot;
    PlayerGameEnded;
    Spectator;
}

enum ActionBtn
{
    Resign;
    ChangeOrientation;
    OfferDraw;
    CancelDraw;
    OfferTakeback;
    CancelTakeback;
    AddTime;
    Rematch;
    Share;
    PlayFromHere;
    Analyze;
    AcceptDraw;
    DeclineDraw;
    AcceptTakeback;
    DeclineTakeback;
    PrevMove;
    NextMove;
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/action_bar.xml"))
class GameActionBar extends VBox implements INetObserver implements IGameBoardObserver
{
    private var mode:Mode;

    private var isCorrespondence:Bool;
    private var move(default, set):Int;

    private var enableDrawSinceMove:Int;
    private var enableTakebackSinceMove:Int;
    private var enableAddTimeSinceMove:Int;
    private var changeAbortToResignAfterMove:Int;
    private var resignConfirmationMessage:String;

    private var compact:Bool;
    private var onBtnPressed:ActionBtn->Void;

    private var incomingDrawRequestPending:Bool;
    private var incomingTakebackRequestPending:Bool;

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case GameEnded(_, rematchPossible, _, _):
                btnBar.hidden = false;
                drawRequestBox.hidden = true;
                takebackRequestBox.hidden = true;
                if (mode == PlayerOngoingGame || mode == PlayerOngoingVersusBot)
                    setMode(PlayerGameEnded);
                if (rematchPossible)
                    Timer.delay(() -> {if (rematchBtn != null) rematchBtn.disabled = true;}, 1000 * 60 * Constants.minutesBeforeRematchExpires);
                else
                    rematchBtn.disabled = true;
            case DrawOffered(_):
                if (mode == PlayerOngoingGame)
                    enableDrawRequest();
            case DrawCancelled(_):
                if (mode == PlayerOngoingGame)
                    disableDrawRequest();
            case TakebackOffered(_):
                if (mode == PlayerOngoingGame)
                    enableTakebackRequest();
            case TakebackCancelled(_):
                if (mode == PlayerOngoingGame)
                    disableTakebackRequest();
            case DrawAccepted(_), DrawDeclined(_):
                if (mode == PlayerOngoingGame)
                {
                    cancelDrawBtn.hidden = true;
                    offerDrawBtn.hidden = false;
                }
            case TakebackAccepted(_), TakebackDeclined(_):
                if (mode == PlayerOngoingGame || mode == PlayerOngoingVersusBot)
                {
                    cancelTakebackBtn.hidden = true;
                    offerTakebackBtn.hidden = false;
                }
            case Move(_, _):
                resetAllRequestsAndOffers();
                move++;
            case Rollback(plysToUndo, _):
                resetAllRequestsAndOffers();
                move -= plysToUndo;
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent) 
    {
        switch event 
        {
            case ContinuationMove(_, _, _):
                resetAllRequestsAndOffers();
                move++;
            default:
        }
    }

    private function set_move(value:Int):Int
    {
        move = value;

        if (mode.match(PlayerGameEnded | Spectator))
            return move;

        if (move < enableTakebackSinceMove)
            offerTakebackBtn.disabled = true;
        else
            offerTakebackBtn.disabled = false;

        if (move < enableDrawSinceMove)
            offerDrawBtn.disabled = true;
        else 
            offerDrawBtn.disabled = false;

        if (move < enableAddTimeSinceMove)
            addTimeBtn.disabled = true;
        else if (!isCorrespondence)
            addTimeBtn.disabled = false;

        if (move < changeAbortToResignAfterMove)
        {
            resignBtn.icon = AbortGameBtnIcon;
            resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_ABORT_TOOLTIP);
            resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);
        }
        else
        {
            resignBtn.icon = ResignBtnIcon;
            resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_TOOLTIP);
            resignConfirmationMessage = Dictionary.getPhrase(RESIGN_CONFIRMATION_MESSAGE);
        }

        return move;
    }

    private function setMode(mode:Mode) 
    {
        this.mode = mode;
        var shownButtons:Array<Button> = switch mode 
        {
            case PlayerOngoingGame: [changeOrientationBtn, offerDrawBtn, offerTakebackBtn, resignBtn, addTimeBtn];
            case PlayerOngoingVersusBot: [changeOrientationBtn, offerTakebackBtn, resignBtn, addTimeBtn];
            case PlayerGameEnded: [changeOrientationBtn, analyzeBtn, shareBtn, playFromPosBtn, rematchBtn];
            case Spectator: [changeOrientationBtn, analyzeBtn, shareBtn, playFromPosBtn];
        }

        if (compact)
        {
            shownButtons.push(prevMoveBtn);
            shownButtons.push(nextMoveBtn);
        }
            
        changeActionButtons(shownButtons);
    }

    private function changeActionButtons(shownButtons:Array<Button>)
    {
        for (i in 0...btnBar.numComponents)
            btnBar.getComponentAt(i).hidden = true;

        var btnWidth:Float = 100 / shownButtons.length;
        for (btn in shownButtons)
        {
            btn.hidden = false;
            btn.percentWidth = btnWidth;
        }
    }

    private function onResignPressed() 
    {
        var confirmed:Bool = Browser.window.confirm(resignConfirmationMessage);
        if (confirmed)
            onBtnPressed(Resign);
    }

    private function onOfferDrawPressed()
    {
        if (!incomingDrawRequestPending)
        {
            offerDrawBtn.hidden = true;
            cancelDrawBtn.hidden = false;
            onBtnPressed(OfferDraw);
        }
        else
        {
            disableDrawRequest();
            onBtnPressed(AcceptDraw);
        }
    }

    private function onCancelDrawPressed()
    {
        cancelDrawBtn.hidden = true;
        offerDrawBtn.hidden = false;
    }

    private function onOfferTakebackPressed()
    {
        if (!incomingTakebackRequestPending)
        {
            if (mode != PlayerOngoingVersusBot)
            {
                offerTakebackBtn.hidden = true;
                cancelTakebackBtn.hidden = false;
            }
            onBtnPressed(OfferTakeback);
        }
        else
        {
            //In theory, should be unreachable, but just to be safe
            disableTakebackRequest();
            onBtnPressed(AcceptTakeback);
        }
    }

    private function onCancelTakebackPressed()
    {
        offerTakebackBtn.hidden = false;
        cancelTakebackBtn.hidden = true;
    }

    private function disableTakebackRequest()
    {
        offerTakebackBtn.disabled = false;
        takebackRequestBox.hidden = true;
        incomingTakebackRequestPending = false;
        if (compact)
        {
            if (incomingDrawRequestPending)
                drawRequestBox.hidden = false;
            else
                btnBar.hidden = false;
        }
    }

    private function disableDrawRequest()
    {
        drawRequestBox.hidden = true;
        incomingDrawRequestPending = false;
        if (compact)
        {
            if (incomingTakebackRequestPending)
                takebackRequestBox.hidden = false;
            else
                btnBar.hidden = false;
        }
    }

    private function enableDrawRequest()
    {
        if (compact)
        {
            btnBar.hidden = true;
            takebackRequestBox.hidden = true;
        }
        drawRequestBox.hidden = false;
        incomingDrawRequestPending = true;
    }

    private function enableTakebackRequest()
    {
        if (compact)
        {
            btnBar.hidden = true;
            drawRequestBox.hidden = true;
        }
        offerTakebackBtn.disabled = true;
        takebackRequestBox.hidden = false;
        incomingTakebackRequestPending = true;
    }

    private function resetAllRequestsAndOffers()
    {
        if (mode != PlayerOngoingGame)
            return;

        cancelTakebackBtn.hidden = true;
        offerTakebackBtn.hidden = false;
        cancelDrawBtn.hidden = true;
        offerDrawBtn.hidden = false;
        disableDrawRequest();
        disableTakebackRequest();
    }

    private function attachHandler(btn:Button, ?typeToForward:ActionBtn, ?localHandler:Void->Void) 
    {
        btn.onClick = e -> {
            if (localHandler != null)
                localHandler();
            if (typeToForward != null)
                onBtnPressed(typeToForward);
        };
    }

    public function init(constructor:LiveGameConstructor, compact:Bool, onBtnPressed:ActionBtn->Void) 
    {
        this.compact = compact;
        this.onBtnPressed = onBtnPressed;
        
        this.enableAddTimeSinceMove = 1;
        this.enableDrawSinceMove = 2;
        this.changeAbortToResignAfterMove = 2;

        this.incomingDrawRequestPending = false;
        this.incomingTakebackRequestPending = false;

        var tc:TimeControl;

        switch constructor 
        {
            case New(whiteRef, blackRef, _, timeControl, startingSituation, _):
                var playerColor:PieceColor = LoginManager.isPlayer(whiteRef)? White : Black;
                var opponentRef:PlayerRef = playerColor == White? blackRef : whiteRef;
                switch opponentRef.concretize() 
                {
                    case Bot(_):
                        setMode(PlayerOngoingVersusBot);
                    default:
                        setMode(PlayerOngoingGame);
                }
                this.enableTakebackSinceMove = startingSituation.turnColor == playerColor? 1 : 2;
                move = 0;
                tc = timeControl;

            case Ongoing(parsedData, _, followedPlayerLogin):
                if (!parsedData.isPlayerParticipant())
                    setMode(Spectator);
                else 
                    switch parsedData.getPlayerOpponentRef().concretize() 
                    {
                        case Bot(_):
                            setMode(PlayerOngoingVersusBot);
                        default:
                            setMode(PlayerOngoingGame);
                    }
                this.enableTakebackSinceMove = parsedData.startingSituation.turnColor == parsedData.getPlayerColor()? 1 : 2;
                move = parsedData.moveCount;
                tc = parsedData.timeControl;

            case Past(parsedData, _):
                setMode(Spectator);
                tc = parsedData.timeControl;
        }

        attachHandler(resignBtn, onResignPressed);
        attachHandler(changeOrientationBtn, ChangeOrientation);
        attachHandler(offerDrawBtn, onOfferDrawPressed);
        attachHandler(cancelDrawBtn, CancelDraw, onCancelDrawPressed);
        attachHandler(acceptDrawBtn, AcceptDraw, disableDrawRequest);
        attachHandler(declineDrawBtn, DeclineDraw, disableDrawRequest);
        attachHandler(offerTakebackBtn, onOfferTakebackPressed);
        attachHandler(cancelTakebackBtn, CancelTakeback, onCancelTakebackPressed);
        attachHandler(acceptTakebackBtn, AcceptTakeback, disableTakebackRequest);
        attachHandler(declineTakebackBtn, DeclineTakeback, disableTakebackRequest);
        attachHandler(addTimeBtn, AddTime);
        attachHandler(shareBtn, Share);
        attachHandler(analyzeBtn, Analyze);
        attachHandler(prevMoveBtn, PrevMove);
        attachHandler(nextMoveBtn, NextMove);
        attachHandler(rematchBtn, Rematch);
        attachHandler(playFromPosBtn, PlayFromHere);

        if (!LoginManager.isLogged())
        {
            rematchBtn.disabled = true;
            playFromPosBtn.disabled = true;
        }

        if (mode == PlayerOngoingVersusBot)
            cancelTakebackBtn.disabled = true;

        this.isCorrespondence = tc.getType() == Correspondence;
        if (isCorrespondence)
            addTimeBtn.disabled = true;
    }

    public function new() 
    {
        super(); 
    }
}