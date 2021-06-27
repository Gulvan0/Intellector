package;

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

    private var takebackRequestBox:HBox;
    private var drawRequestBox:HBox;
    private var bottomTime:Label;
    private var upperTime:Label;
    private var bottomLogin:Label;
    private var upperLogin:Label;
    private var movetable:TableView;
    private var offerDrawBtn:Button;
    private var cancelDrawBtn:Button;
    private var offerTakebackBtn:Button;
    private var cancelTakebackBtn:Button;

    public var onHomePressed:Void->Void;
    public var onPrevPressed:Void->Void;
    public var onNextPressed:Void->Void;
    public var onEndPressed:Void->Void;
    public var onOfferDrawPressed:Void->Void;
    public var onCancelDrawPressed:Void->Void;
    public var onAcceptDrawPressed:Void->Void;
    public var onDeclineDrawPressed:Void->Void;

    private var timer:Timer;
    private var secsPerTurn:Int;
    private var move:Int;

    private var playerColor:PieceColor;
    private var playerTurn:Bool;
    private var lastMoveEntry:Dynamic;

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

        var moveStr = ply.toNotation(situation);
        if (situation.turnColor == Black)
        {
            lastMoveEntry.black_move = moveStr;
            movetable.dataSource.update(movetable.dataSource.size - 1, lastMoveEntry);
        }
        else 
        {
            lastMoveEntry = {"num": '$move', "white_move": moveStr, "black_move": ""};
            movetable.dataSource.add(lastMoveEntry);
        }
        waitAndScroll();

        move++;

        if (!situation.isMating(ply) && move > 2)
        {
            if (playerTurn) //Because corrections have already been applied if it is the opponent's turn ("correct, then move" server rule)
                bottomTime.text = addBonus(bottomTime.text);
            launchTimer();
        }
        
        playerTurn = situation.turnColor != playerColor;
    }

    private function waitAndScroll() 
    {
        var t:Timer = new Timer(100);
        t.run = () -> {
            t.stop(); 
            scrollToMax();
        }    
    }

    private function scrollToMax() 
    {
        var vscroll = movetable.findComponent(VerticalScroll, false);
        if (vscroll != null)
            vscroll.pos = vscroll.max;
    }

    public function writeMove(color:PieceColor, s:String)
    {
        if (color == Black)
        {
            lastMoveEntry.black_move = s;
            movetable.dataSource.update(movetable.dataSource.size - 1, lastMoveEntry);
        }
        else 
        {
            lastMoveEntry = {"num": '$move', "white_move": s, "black_move": ""};
            movetable.dataSource.add(lastMoveEntry);
        }

        move++;
        playerTurn = color != playerColor;
    }

    public function launchTimer()
    {
        timer = new Timer(1000);
        timer.run = timerRun;
    }

    public function terminate() 
    {
        if (timer != null)
            timer.stop();
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

    public function takebackOfferHideCancelShow() 
    {
        offerDrawBtn.visible = true;
        cancelDrawBtn.visible = false;
    }

    public function drawOfferShowCancelHide() 
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
            //TODO: delegate
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
			//TODO: delegate
        }

        takebackRequestBox.visible = false;
        container.addComponent(takebackRequestBox);
    }

    private function buildPlyScrollBtns(container:VBox)
    {
        var matchViewControls:HBox = new HBox();

        var homeBtn = new haxe.ui.components.Button();
		homeBtn.width = (250 - 5.3 * 3) / 4;
		homeBtn.text = "❙◄◄";
		matchViewControls.addComponent(homeBtn);

		homeBtn.onClick = (e) -> {
			onHomePressed();
        }

        var prevBtn = new haxe.ui.components.Button();
		prevBtn.width = (250 - 5.3 * 3) / 4;
		prevBtn.text = "◄";
		matchViewControls.addComponent(prevBtn);

		prevBtn.onClick = (e) -> {
			onPrevPressed();
        }

        var nextBtn = new haxe.ui.components.Button();
		nextBtn.width = (250 - 5.3 * 3) / 4;
		nextBtn.text = "►";
		matchViewControls.addComponent(nextBtn);

		nextBtn.onClick = (e) -> {
			onNextPressed();
        }

        var endBtn = new haxe.ui.components.Button();
		endBtn.width = (250 - 5.3 * 3) / 4;
		endBtn.text = "►►❙";
		matchViewControls.addComponent(endBtn);

		endBtn.onClick = (e) -> {
			onEndPressed();
        }

        container.addComponent(matchViewControls);
    }

    private function buildSpecialBtns(container:VBox)
    {
        var resignAndDraw:HBox = new HBox();

        var resignBtn = new haxe.ui.components.Button();
		resignBtn.width = (250 - 5.3) / 2;
		resignBtn.text = Dictionary.getPhrase(RESIGN_BTN_TEXT);
		resignAndDraw.addComponent(resignBtn);

		resignBtn.onClick = (e) -> {
			var confirmed = Browser.window.confirm(Dictionary.getPhrase(RESIGN_CONFIRMATION_MESSAGE));

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
            takebackOfferHideCancelShow();
            Networker.offerTakeback();
        }

        cancelTakebackBtn = new Button();
		cancelTakebackBtn.width = 250;
		cancelTakebackBtn.text = Dictionary.getPhrase(CANCEL_TAKEBACK_BTN_TEXT);
        cancelTakebackBtn.visible = false;
		container.addComponent(cancelTakebackBtn);

		cancelTakebackBtn.onClick = (e) -> {
            takebackOfferShowCancelHide();
		    Networker.cancelTakeback();
        }
    }

    //--------------------------------------------------------------------------------------------------------------------------------------------------------

    public function new(simplified:Bool, startSecs:Int, secsPerTurn:Int, playerLogin:String, opponentLogin:String, playerIsWhite:Bool) 
    {
        super();
        move = 1;
        this.secsPerTurn = secsPerTurn;
        playerColor = playerIsWhite? White : Black;
        playerTurn = playerIsWhite;

        var strStart = secsToString(startSecs);
        var timeStyle:Style = {fontSize: 40};
        var loginStyle:Style = {fontSize: 24};

        var box:VBox = new VBox();

        upperTime = new Label();
        upperTime.text = strStart;
        upperTime.customStyle = timeStyle;
        box.addComponent(upperTime);

        upperLogin = new Label();
        upperLogin.text = opponentLogin;
        upperLogin.customStyle = loginStyle;
        box.addComponent(upperLogin);

        if (!simplified)
        {
            buildTakebackRequestBox(box);
            buildDrawRequestBox(box);
        }

        buildPlyScrollBtns(box);

        movetable = ComponentMacros.buildComponent("assets/layouts/movetable.xml");
        box.addComponent(movetable);

        if (!simplified)
            buildSpecialBtns(box);

        bottomLogin = new Label();
        bottomLogin.text = playerLogin;
        bottomLogin.customStyle = loginStyle;
        box.addComponent(bottomLogin);

        bottomTime = new Label();
        bottomTime.text = strStart;
        bottomTime.customStyle = timeStyle;
        box.addComponent(bottomTime);

        addChild(box);
    }
}