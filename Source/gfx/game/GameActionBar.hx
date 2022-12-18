package gfx.game;

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
                if (mode == PlayerOngoingGame)
                    setMode(PlayerGameEnded);
                if (rematchPossible)
                    Timer.delay(() -> {if (rematchBtn != null) rematchBtn.disabled = true;}, 1000 * 60 * Constants.minutesBeforeRematchExpires);
                else
                    rematchBtn.disabled = true;
            case DrawOffered(_):
                if (compact)
                {
                    btnBar.hidden = true;
                    takebackRequestBox.hidden = true;
                }
                drawRequestBox.hidden = false;
                incomingDrawRequestPending = true;
            case DrawCancelled(_):
                disableDrawRequest();
            case TakebackOffered(_):
                if (compact)
                {
                    btnBar.hidden = true;
                    drawRequestBox.hidden = true;
                }
                offerTakebackBtn.disabled = true;
                takebackRequestBox.hidden = false;
                incomingTakebackRequestPending = true;
            case TakebackCancelled(_):
                disableTakebackRequest();
            case DrawAccepted(_), DrawDeclined(_):
                cancelDrawBtn.hidden = true;
                offerDrawBtn.hidden = false;
            case TakebackAccepted(_), TakebackDeclined(_):
                cancelTakebackBtn.hidden = true;
                offerTakebackBtn.hidden = false;
            case Move(_, _):
                move++;
            case Rollback(plysToUndo, _):
                shutAllTakebackRequests();
                move -= plysToUndo;
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent) 
    {
        switch event 
        {
            case ContinuationMove(_, _, _):
                move++;
            default:
        }
    }

    private function set_move(value:Int):Int
    {
        move = value;

        if (mode != PlayerOngoingGame)
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
        else
            addTimeBtn.disabled = false;

        if (move < changeAbortToResignAfterMove)
        {
            resignBtn.text = "✖";
            resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_ABORT_TOOLTIP);
            resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);
        }
        else
        {
            resignBtn.text = "⚐";
            resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_TOOLTIP);
            resignConfirmationMessage = Dictionary.getPhrase(RESIGN_CONFIRMATION_MESSAGE);
        }

        return move;
    }

    private function shutAllTakebackRequests()
    {
        if (mode != PlayerOngoingGame)
            return;

        cancelTakebackBtn.hidden = true;
        offerTakebackBtn.hidden = false;
        disableTakebackRequest();
    }

    private function setMode(mode:Mode) 
    {
        this.mode = mode;
        var shownButtons:Array<Button> = switch mode 
        {
            case PlayerOngoingGame: [changeOrientationBtn, offerDrawBtn, offerTakebackBtn, resignBtn, addTimeBtn];
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

    private function onOfferTakebackPressed()
    {
        if (!incomingTakebackRequestPending)
        {
            offerTakebackBtn.hidden = true;
            cancelTakebackBtn.hidden = false;
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

        switch constructor 
        {
            case New(_, _, _, _, startingSituation, _):
                setMode(PlayerOngoingGame);
                this.enableTakebackSinceMove = startingSituation.turnColor == White? 1 : 2;
                move = 0;

            case Ongoing(parsedData, _, followedPlayerLogin):
                setMode(parsedData.isPlayerParticipant()? PlayerOngoingGame : Spectator);
                this.enableTakebackSinceMove = parsedData.startingSituation.turnColor == White? 1 : 2;
                move = parsedData.moveCount;

            case Past(parsedData, _):
                setMode(Spectator);
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
    }

    public function new() 
    {
        super(); 
    }
}