package gfx.game;

import haxe.ui.containers.VBox;
import struct.PieceColor;
import js.Browser;
import net.ServerEvent;
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
    Analyze;
    AcceptDraw;
    DeclineDraw;
    AcceptTakeback;
    DeclineTakeback;
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/action_bar.xml"))
class GameActionBar extends VBox
{
    private var mode:Mode;
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
            case GameEnded(_, _):
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
            default:
        }
    }

    public function onMoveNumberUpdated(move:Int) 
    {
        if (mode != PlayerOngoingGame)
            return;

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
    }

    public function shutAllTakebackRequests()
    {
        if (mode != PlayerOngoingGame)
            return;

        cancelTakebackBtn.hidden = true;
        offerTakebackBtn.hidden = false;
        disableTakebackRequest();
    }

    public function setMode(mode:Mode) 
    {
        this.mode = mode;
        var shownButtons:Array<Button> = switch mode 
        {
            case PlayerOngoingGame: [changeOrientationBtn, offerDrawBtn, offerTakebackBtn, resignBtn, addTimeBtn];
            case PlayerGameEnded: [changeOrientationBtn, analyzeBtn, shareBtn, rematchBtn];
            case Spectator: [changeOrientationBtn, analyzeBtn, shareBtn];
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

    public function init(compact:Bool, playingAs:Null<PieceColor>, onBtnPressed:ActionBtn->Void) 
    {
        this.compact = compact;
        this.onBtnPressed = onBtnPressed;
        this.enableDrawAfterMove = 2;
        this.enableTakebackAfterMove = playingAs == White? 1 : 2;   
        this.changeAbortToResignAfterMove = 2;
        this.resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);

        incomingDrawRequestPending = false;
        incomingTakebackRequestPending = false;

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

        setMode(playingAs == null? Spectator : PlayerOngoingGame);
    }

    public function new() 
    {
        super(); 
    }
}