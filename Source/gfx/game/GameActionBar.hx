package gfx.game;

import gameboard.GameBoard.IGameBoardObserver;
import net.EventProcessingQueue.INetObserver;
import gameboard.GameBoard.GameBoardEvent;
import haxe.ui.containers.VBox;
import struct.PieceColor;
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
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/action_bar.xml"))
class GameActionBar extends VBox implements INetObserver implements IGameBoardObserver
{
    private var mode:Mode;

    private var move(default, set):Int;

    private var enableDrawAfterMove:Int;
    private var enableTakebackAfterMove:Int;
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
            case GameEnded(_, _, _, _):
                btnBar.hidden = false;
                drawRequestBox.hidden = true;
                takebackRequestBox.hidden = true;
                if (mode == PlayerOngoingGame)
                    setMode(PlayerGameEnded);
            case DrawOffered:
                if (compact)
                {
                    btnBar.hidden = true;
                    takebackRequestBox.hidden = true;
                }
                drawRequestBox.hidden = false;
                incomingDrawRequestPending = true;
            case DrawCancelled:
                disableDrawRequest();
            case TakebackOffered:
                if (compact)
                {
                    btnBar.hidden = true;
                    drawRequestBox.hidden = true;
                }
                offerTakebackBtn.disabled = true;
                takebackRequestBox.hidden = false;
                incomingTakebackRequestPending = true;
            case TakebackCancelled:
                disableTakebackRequest();
            case DrawAccepted, DrawDeclined:
                cancelDrawBtn.hidden = true;
                offerDrawBtn.hidden = false;
            case TakebackAccepted, TakebackDeclined:
                cancelTakebackBtn.hidden = true;
                offerTakebackBtn.hidden = false;
            case Move(_, _, _, _, _, _, _, _):
                move++;
            case Rollback(plysToUndo, _, _, _):
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

        if (move < enableTakebackAfterMove)
            offerTakebackBtn.disabled = true;
        else
            offerTakebackBtn.disabled = false;

        if (move < enableDrawAfterMove)
            offerDrawBtn.disabled = true;
        else 
            offerDrawBtn.disabled = false;

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
        
        this.enableDrawAfterMove = 2;
        this.changeAbortToResignAfterMove = 2;

        this.incomingDrawRequestPending = false;
        this.incomingTakebackRequestPending = false;

        switch constructor 
        {
            case New(whiteLogin, blackLogin, timeControl, startingSituation, _):
                setMode(PlayerOngoingGame);
                this.enableTakebackAfterMove = startingSituation.turnColor == White? 1 : 2;
                move = 0;

            case Ongoing(parsedData, _, _, _, followedPlayerLogin):
                setMode(followedPlayerLogin != null? Spectator : PlayerOngoingGame);
                this.enableTakebackAfterMove = parsedData.startingSituation.turnColor == White? 1 : 2;
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
        attachHandler(rematchBtn, Rematch);
        attachHandler(shareBtn, Share);
        attachHandler(analyzeBtn, Analyze);
        attachHandler(playFromPosBtn, PlayFromHere);
    }

    public function new() 
    {
        super(); 
    }
}