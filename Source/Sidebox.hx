package;

import gfx.components.utils.PlyScrollType;
import gfx.components.common.MoveNavigator;
import haxe.ui.components.Button;
import haxe.ui.util.Color;
import dict.Dictionary;
import js.Browser;
import haxe.ui.containers.HBox;
import struct.Situation;
import struct.Ply;
import haxe.ui.components.VerticalScroll;
import openfl.display.StageAlign;
import haxe.Timer;
import struct.PieceType;
import struct.PieceColor;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import haxe.ui.containers.TableView;
import haxe.ui.components.Label;
import openfl.display.Sprite;

class Sidebox extends Sprite
{
    public var simplified:Bool;

    private var takebackRequestBox:HBox;
    private var drawRequestBox:HBox;
    private var bottomTime:Label;
    private var upperTime:Label;
    private var navigator:MoveNavigator;
    private var bottomLogin:Label;
    private var upperLogin:Label;
    private var resignBtn:Button;
    private var offerDrawBtn:Button;
    private var cancelDrawBtn:Button;
    private var offerTakebackBtn:Button;
    private var cancelTakebackBtn:Button;

    public var onOfferDrawPressed:Void->Void;
    public var onCancelDrawPressed:Void->Void;
    public var onAcceptDrawPressed:Void->Void;
    public var onDeclineDrawPressed:Void->Void;
    public var onOfferTakebackPressed:Void->Void;
    public var onCancelTakebackPressed:Void->Void;
    public var onAcceptTakebackPressed:Void->Void;
    public var onDeclineTakebackPressed:Void->Void;

    private var resignConfirmationMessage:String;

    private var timer:Timer;
    private var secsPerTurn:Int;
    private var move:Int;

    private var playerColor:PieceColor;
    private var playerTurn:Bool;

    private inline function numRep(v:Int)
    {
        return v < 10? '0$v' : '$v';
    }

    private function secsToString(secs:Int) 
    {
        var secsLeft:Int = secs % 60;
        var minsLeft:Int = cast (secs - secsLeft)/60;
        var minRepresentation = numRep(minsLeft);
        var secRepresentation = numRep(secsLeft);
        return '$minRepresentation:$secRepresentation';    
    }

    private function timerRun() 
    {
        var timeLabel = playerTurn? bottomTime : upperTime;
        var timeNumbers = timeLabel.text.split(":");
        if (timeNumbers[1] == "00")
        {
            if (timeNumbers[0] == "00")
            {
                terminate();
                Networker.reqTimeoutCheck();
                return;
            }
            timeLabel.text = '${numRep(Std.parseInt(timeNumbers[0])-1)}:59';
        }
        else
            timeLabel.text = '${timeNumbers[0]}:${numRep(Std.parseInt(timeNumbers[1])-1)}';
    }

    private function addBonus(text:String) 
    {
        var timeNumbers = text.split(":").map(Std.parseInt);
        timeNumbers[0] += Math.floor((timeNumbers[1] + secsPerTurn) / 60);
        timeNumbers[1] = (timeNumbers[1] + secsPerTurn) % 60;
        return '${numRep(timeNumbers[0])}:${numRep(timeNumbers[1])}';
    }

    public function hasIncomingTakebackRequest():Bool
    {
        return takebackRequestBox.visible;
    }

    public function correctTime(correctedSecsWhite:Int, correctedSecsBlack:Int) 
    {
        if (playerColor == White)
        {
            bottomTime.text = secsToString(correctedSecsWhite);
            upperTime.text = secsToString(correctedSecsBlack);
        }
        else
        {
            upperTime.text = secsToString(correctedSecsWhite);
            bottomTime.text = secsToString(correctedSecsBlack);
        }
    }

    public function makeMove(ply:Ply, situation:Situation) 
    {
        if (timer != null)
            timer.stop();

        navigator.writePly(ply, situation);
        navigator.scrollAfterDelay();

        move++;
        if (!simplified)
        {
            if (move == 2 && playerColor == White || move == 3 && playerColor == Black)
            {
                offerTakebackBtn.disabled = false;
                cancelTakebackBtn.disabled = false;
            }

            if (move == 3)
            {
                offerDrawBtn.disabled = false;
                cancelDrawBtn.disabled = false;
                resignBtn.text = Dictionary.getPhrase(RESIGN_BTN_TEXT);
                resignConfirmationMessage = Dictionary.getPhrase(RESIGN_CONFIRMATION_MESSAGE);
            }
        }

        if (!situation.isMating(ply) && move > 2 && secsPerTurn != null)
        {
            if (playerTurn) //Because corrections have already been applied if it is the opponent's turn ("correct, then move" server rule)
                bottomTime.text = addBonus(bottomTime.text);
            launchTimer();
        }
        
        playerTurn = situation.turnColor != playerColor;
    }

    public function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        move -= cnt;

        if (!simplified)
        {
            hideTakebackRequestBox();
            takebackOfferShowCancelHide();

            if (move < 2 && playerColor == White || move < 3 && playerColor == Black)
            {
                offerTakebackBtn.disabled = true;
                cancelTakebackBtn.disabled = true;
            }

            if (move < 3)
            {
                offerDrawBtn.disabled = true;
                cancelDrawBtn.disabled = true;
                resignBtn.text = Dictionary.getPhrase(RESIGN_BTN_ABORT_TEXT);
                resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);
            }
        }
        
        if (cnt % 2 == 1)
            playerTurn = !playerTurn;

        navigator.revertPlys(cnt);
    }

    public function launchTimer()
    {
        if (timer != null)
            timer.stop();
        timer = new Timer(1000);
        timer.run = timerRun;
    }

    public function terminate() 
    {
        if (timer != null)
            timer.stop();

        if (!simplified)
        {
            resignBtn.disabled = true;
            offerDrawBtn.disabled = true;
            cancelDrawBtn.disabled = true;
            offerTakebackBtn.disabled = true;
            cancelTakebackBtn.disabled = true;
        }
    }

    public function showDrawRequestBox() 
    {
        drawRequestBox.visible = true;
    }

    public function hideDrawRequestBox() 
    {
        drawRequestBox.visible = false;
    }

    public function showTakebackRequestBox() 
    {
        takebackRequestBox.visible = true;
    }

    public function hideTakebackRequestBox() 
    {
        takebackRequestBox.visible = false;
    }

    public function drawOfferHideCancelShow() 
    {
        offerDrawBtn.visible = false;
        cancelDrawBtn.visible = true;
    }

    public function drawOfferShowCancelHide() 
    {
        offerDrawBtn.visible = true;
        cancelDrawBtn.visible = false;
    }

    public function takebackOfferHideCancelShow() 
    {
        offerTakebackBtn.visible = false;
        cancelTakebackBtn.visible = true;
    }

    public function takebackOfferShowCancelHide() 
    {
        offerTakebackBtn.visible = true;
        cancelTakebackBtn.visible = false;
    }

    //--------------------------------------------------------------------------------------------------------------------------------------------------------

    private function buildDrawRequestBox(container:VBox)
    {
        drawRequestBox = new HBox();

        var declineBtn2 = new haxe.ui.components.Button();
		declineBtn2.width = 40;
        declineBtn2.text = "✘";
        declineBtn2.color = Color.fromString("red");
		drawRequestBox.addComponent(declineBtn2);

		declineBtn2.onClick = (e) -> {
			onDeclineDrawPressed();
        }

        var requestLabel2:Label = new Label();
        requestLabel2.text = Dictionary.getPhrase(DRAW_QUESTION_TEXT);
        requestLabel2.width = 250 - 40 * 2 - 10;
        requestLabel2.textAlign = "center";
        drawRequestBox.addComponent(requestLabel2);

        var acceptBtn2 = new haxe.ui.components.Button();
		acceptBtn2.width = 40;
        acceptBtn2.text = "✔";
        acceptBtn2.color = Color.fromString("green");
		drawRequestBox.addComponent(acceptBtn2);

		acceptBtn2.onClick = (e) -> {
			onAcceptDrawPressed();
        }

        drawRequestBox.visible = false;
        container.addComponent(drawRequestBox);
    }

    private function buildTakebackRequestBox(container:VBox)
    {
        takebackRequestBox = new HBox();

        var declineBtn = new haxe.ui.components.Button();
		declineBtn.width = 40;
        declineBtn.text = "✘";
        declineBtn.color = Color.fromString("red");
		takebackRequestBox.addComponent(declineBtn);

		declineBtn.onClick = (e) -> {
            onDeclineTakebackPressed();
        }

        var requestLabel:Label = new Label();
        requestLabel.text = Dictionary.getPhrase(TAKEBACK_QUESTION_TEXT);
        requestLabel.width = 250 - 40 * 2 - 10;
        requestLabel.textAlign = "center";
        takebackRequestBox.addComponent(requestLabel);

        var acceptBtn = new haxe.ui.components.Button();
		acceptBtn.width = 40;
        acceptBtn.text = "✔";
        acceptBtn.color = Color.fromString("green");
		takebackRequestBox.addComponent(acceptBtn);

		acceptBtn.onClick = (e) -> {
			onAcceptTakebackPressed();
        }

        takebackRequestBox.visible = false;
        container.addComponent(takebackRequestBox);
    }

    private function buildSpecialBtns(container:VBox)
    {
        var resignAndDraw:HBox = new HBox();

        resignBtn = new Button();
		resignBtn.width = (250 - 5.3) / 2;
		resignBtn.text = Dictionary.getPhrase(RESIGN_BTN_TEXT);
		resignAndDraw.addComponent(resignBtn);

		resignBtn.onClick = (e) -> {
			var confirmed = Browser.window.confirm(resignConfirmationMessage);

			if (confirmed)
				Networker.emit("resign", {});
        }
        
        offerDrawBtn = new Button();
		offerDrawBtn.width = (250 - 5.3) / 2;
		offerDrawBtn.text = Dictionary.getPhrase(OFFER_DRAW_BTN_TEXT);
		resignAndDraw.addComponent(offerDrawBtn);

		offerDrawBtn.onClick = (e) -> {
            onOfferDrawPressed();
        }
        
        cancelDrawBtn = new Button();
		cancelDrawBtn.width = (250 - 5.3) / 2;
        cancelDrawBtn.text = Dictionary.getPhrase(CANCEL_DRAW_BTN_TEXT);
        cancelDrawBtn.visible = false;
		resignAndDraw.addComponent(cancelDrawBtn);

		cancelDrawBtn.onClick = (e) -> {
            onCancelDrawPressed();
        }
        
        container.addComponent(resignAndDraw);

        offerTakebackBtn = new Button();
		offerTakebackBtn.width = 250;
		offerTakebackBtn.text = Dictionary.getPhrase(TAKEBACK_BTN_TEXT);
		container.addComponent(offerTakebackBtn);

		offerTakebackBtn.onClick = (e) -> {
            onOfferTakebackPressed();
        }

        cancelTakebackBtn = new Button();
		cancelTakebackBtn.width = 250;
		cancelTakebackBtn.text = Dictionary.getPhrase(CANCEL_TAKEBACK_BTN_TEXT);
        cancelTakebackBtn.visible = false;
		container.addComponent(cancelTakebackBtn);

		cancelTakebackBtn.onClick = (e) -> {
            onCancelTakebackPressed();
        }

        offerDrawBtn.disabled = true;
        cancelDrawBtn.disabled = true;
        offerTakebackBtn.disabled = true;
        cancelTakebackBtn.disabled = true;
        resignBtn.text = Dictionary.getPhrase(RESIGN_BTN_ABORT_TEXT);
        resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);
    }

    //--------------------------------------------------------------------------------------------------------------------------------------------------------

    public function new(simplified:Bool, startSecs:Null<Int>, secsPerTurn:Null<Int>, playerLogin:String, opponentLogin:String, playerIsWhite:Bool, onClickCallback:PlyScrollType->Void) 
    {
        super();
        this.simplified = simplified;
        this.secsPerTurn = secsPerTurn;
        move = 1;
        playerColor = playerIsWhite? White : Black;
        playerTurn = playerIsWhite;

        var strStart = startSecs == null? null : secsToString(startSecs);
        var timeStyle:Style = {fontSize: 40};
        var loginStyle:Style = {fontSize: 24};

        var box:VBox = new VBox();

        if (startSecs != null && secsPerTurn != null)
        {
            upperTime = new Label();
            upperTime.text = strStart;
            upperTime.customStyle = timeStyle;
            box.addComponent(upperTime);
        }

        upperLogin = new Label();
        upperLogin.text = opponentLogin;
        upperLogin.customStyle = loginStyle;
        box.addComponent(upperLogin);

        if (!simplified)
        {
            buildTakebackRequestBox(box);
            buildDrawRequestBox(box);
        }

        navigator = new MoveNavigator(onClickCallback);
        box.addComponent(navigator);

        if (!simplified)
            buildSpecialBtns(box);

        bottomLogin = new Label();
        bottomLogin.text = playerLogin;
        bottomLogin.customStyle = loginStyle;
        box.addComponent(bottomLogin);

        if (startSecs != null && secsPerTurn != null)
        {
            bottomTime = new Label();
            bottomTime.text = strStart;
            bottomTime.customStyle = timeStyle;
            box.addComponent(bottomTime);
        }

        addChild(box);
    }
}