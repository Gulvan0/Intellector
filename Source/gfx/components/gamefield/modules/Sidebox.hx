package gfx.components.gamefield.modules;

import gfx.components.gamefield.common.TimeLeftLabel;
import dict.Phrase;
import gfx.utils.PlyScrollType;
import gfx.components.gamefield.common.MoveNavigator;
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
    private static var loginStyle:Style = {fontSize: 24};

    private static var BUTTON_BOX_WIDTH:Float = 250;
    private static var BUTTON_HORIZONTAL_INTERVAL:Float = 5.3;

    private static var FULL_BUTTON_WIDTH:Float = BUTTON_BOX_WIDTH;
    private static var HALVED_BUTTON_WIDTH:Float = (BUTTON_BOX_WIDTH - BUTTON_HORIZONTAL_INTERVAL) / 2;

    private static var ACCEPT_DECLINE_BTN_WIDTH:Float = 40;
    private static var REQUEST_ELEMENTS_INTERVAL:Float = 10;
    private static var REQUEST_LABEL_WIDTH:Float = BUTTON_BOX_WIDTH - ACCEPT_DECLINE_BTN_WIDTH * 2 - REQUEST_ELEMENTS_INTERVAL;

    public var simplified:Bool;

    private var bottomTime:TimeLeftLabel;
    private var upperTime:TimeLeftLabel;

    private var takebackRequestBox:HBox;
    private var drawRequestBox:HBox;
    private var navigator:MoveNavigator;
    private var bottomLogin:Label;
    private var upperLogin:Label;
    private var resignBtn:Button;
    private var offerDrawBtn:Button;
    private var cancelDrawBtn:Button;
    private var offerTakebackBtn:Button;
    private var cancelTakebackBtn:Button;
    private var rematchBtn:Button;
    private var exploreBtn:Button;
    private var addTimeBtn:Button;

    public var onOfferDrawPressed:Void->Void;
    public var onCancelDrawPressed:Void->Void;
    public var onAcceptDrawPressed:Void->Void;
    public var onDeclineDrawPressed:Void->Void;
    public var onOfferTakebackPressed:Void->Void;
    public var onCancelTakebackPressed:Void->Void;
    public var onAcceptTakebackPressed:Void->Void;
    public var onDeclineTakebackPressed:Void->Void;
    public var onExportSIPRequested:Void->Void;
    public var onExploreInAnalysisRequest:Void->Void;

    private var resignConfirmationMessage:String;

    private var playerTurn:Bool;
    private var move:Int;

    private var playerColor:PieceColor;
    private var secsPerTurn:Int;

    public function correctTime(correctedSecsWhite:Float, correctedSecsBlack:Float, actualTimestamp:Float) 
    {
        if (playerColor == White)
        {
            bottomTime.correctTime(correctedSecsWhite, actualTimestamp);
            upperTime.correctTime(correctedSecsBlack, actualTimestamp);
        }
        else
        {
            upperTime.correctTime(correctedSecsWhite, actualTimestamp);
            bottomTime.correctTime(correctedSecsBlack, actualTimestamp);
        }
    }

    public function terminate() 
    {
        upperTime.stopTimer();
        bottomTime.stopTimer();

        if (!simplified)
        {
            resignBtn.visible = false;
            offerDrawBtn.visible = false;
            cancelDrawBtn.visible = false;
            offerTakebackBtn.visible = false;
            cancelTakebackBtn.visible = false;
            addTimeBtn.visible = false;
            rematchBtn.visible = true;
            exploreBtn.visible = true;
        }
    }

    //========================================================================================================================================================================

    public function makeMove(ply:Ply, situation:Situation) 
    {
        if (!situation.isMating(ply) && move >= 2 && secsPerTurn != null)
        {
            if (playerTurn)
            {
                bottomTime.addTime(secsPerTurn);
                bottomTime.stopTimer();
                upperTime.launchTimer();
            }
            else
            {
                //Does not add bonus because corrections have already been applied if it is the opponent's turn ("correct, then move" server rule)
                upperTime.stopTimer();
                bottomTime.launchTimer();
            }
        }

        navigator.writePly(ply, situation);
        navigator.scrollAfterDelay();

        if (!simplified)
        {
            if (move == 1 && playerColor == White || move == 2 && playerColor == Black)
            {
                offerTakebackBtn.disabled = false;
                cancelTakebackBtn.disabled = false;
            }

            if (move == 2)
            {
                offerDrawBtn.disabled = false;
                cancelDrawBtn.disabled = false;
                resignBtn.text = Dictionary.getPhrase(RESIGN_BTN_TEXT);
                resignConfirmationMessage = Dictionary.getPhrase(RESIGN_CONFIRMATION_MESSAGE);
            }
        }
        
        move++;
        playerTurn = situation.turnColor != playerColor;
    }

    public function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        move -= cnt;
        if (cnt % 2 == 1)
        {
            playerTurn = !playerTurn;
            if (playerTurn)
            {
                upperTime.stopTimer();
                bottomTime.launchTimer();
            }
            else
            {
                bottomTime.stopTimer();
                upperTime.launchTimer();
            }
        }

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

        navigator.revertPlys(cnt);
    }

    //===========================================================================================================================================================

    public function hasIncomingTakebackRequest():Bool
    {
        return takebackRequestBox.visible;
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

    private function onResignPressed() 
    {
        var confirmed = Browser.window.confirm(resignConfirmationMessage);

		if (confirmed)
			Networker.emit("resign", {});
    }

    //===========================================================================================================================================================

    private function buildSpecialBtns(container:VBox, opponentLogin:String, startSecs:Null<Int>, secsPerTurn:Null<Int>, playerIsWhite:Bool)
    {
        resignBtn = constructBtn(HALVED_BUTTON_WIDTH, RESIGN_BTN_ABORT_TEXT,  (e) -> {onResignPressed();});
        offerDrawBtn = constructBtn(HALVED_BUTTON_WIDTH, OFFER_DRAW_BTN_TEXT, (e) -> {onOfferDrawPressed();});
        cancelDrawBtn = constructBtn(HALVED_BUTTON_WIDTH, CANCEL_DRAW_BTN_TEXT, (e) -> {onCancelDrawPressed();}, false);
        
        var resignAndDraw:HBox = new HBox();
        resignAndDraw.addComponent(resignBtn);
        resignAndDraw.addComponent(offerDrawBtn);
        resignAndDraw.addComponent(cancelDrawBtn);
        
        addTimeBtn = constructBtn(FULL_BUTTON_WIDTH, ADD_TIME_BTN_TEXT,  (e) -> {Networker.addTime();});
        offerTakebackBtn = constructBtn(FULL_BUTTON_WIDTH, TAKEBACK_BTN_TEXT, (e) -> {onOfferTakebackPressed();});
        cancelTakebackBtn = constructBtn(FULL_BUTTON_WIDTH, CANCEL_TAKEBACK_BTN_TEXT, (e) -> {onCancelTakebackPressed();}, false);
        rematchBtn = constructBtn(FULL_BUTTON_WIDTH, REMATCH,  (e) -> {Networker.sendChallenge(opponentLogin, startSecs, secsPerTurn, playerIsWhite? Black : White);}, false);
        
        container.addComponent(resignAndDraw);
		container.addComponent(addTimeBtn);
		container.addComponent(offerTakebackBtn);
        container.addComponent(cancelTakebackBtn);
		container.addComponent(rematchBtn);

        offerDrawBtn.disabled = true;
        cancelDrawBtn.disabled = true;
        offerTakebackBtn.disabled = true;
        cancelTakebackBtn.disabled = true;
        resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);
    }

    public function new(spectators:Bool, startSecs:Null<Int>, secsPerTurn:Null<Int>, playerLogin:String, opponentLogin:String, playerIsWhite:Bool, onClickCallback:PlyScrollType->Void) 
    {
        super();
        this.simplified = spectators;
        this.secsPerTurn = secsPerTurn;
        move = 1;
        playerColor = playerIsWhite? White : Black;
        playerTurn = playerIsWhite;
        var hasTime:Bool = startSecs != null && secsPerTurn != null;

        if (hasTime)
        {
            upperTime = new TimeLeftLabel(startSecs, false, startSecs >= 90);
            bottomTime = new TimeLeftLabel(startSecs, !spectators, startSecs >= 90);
        }

        upperLogin = buildLabel(opponentLogin, loginStyle);
        navigator = new MoveNavigator(onClickCallback);
        exploreBtn = constructBtn(250, EXPLORE_IN_ANALYSIS_BTN_TEXT, (e) -> {onExploreInAnalysisRequest();}, spectators);
        bottomLogin = buildLabel(playerLogin, loginStyle);

        var box:VBox = new VBox();
        box.addComponent(upperTime);

        if (hasTime)
            box.addComponent(upperLogin);

        if (!spectators)
        {
            takebackRequestBox = buildRequestBox(box, TAKEBACK_QUESTION_TEXT, (e) -> {onAcceptTakebackPressed();}, (e) -> {onDeclineTakebackPressed();});
            drawRequestBox = buildRequestBox(box, DRAW_QUESTION_TEXT, (e) -> {onAcceptDrawPressed();}, (e) -> {onDeclineDrawPressed();});
        }

        box.addComponent(navigator);
        box.addComponent(exploreBtn);

        if (!spectators)
            buildSpecialBtns(box, opponentLogin, startSecs, secsPerTurn, playerIsWhite);

        box.addComponent(constructBtn(250, ANALYSIS_EXPORT_SIP,  (e) -> {onExportSIPRequested();}));
        box.addComponent(bottomLogin);

        if (hasTime)
            box.addComponent(bottomTime);

        addChild(box);
    }

    private function constructBtn(width:Float, phrase:Phrase, onClick:Dynamic->Void, ?visible:Bool = true, ?color:Color):Button
    {
        return constructBtnStr(width, Dictionary.getPhrase(phrase), onClick, visible, color);
    }

    private function constructBtnStr(width:Float, text:String, onClick:Dynamic->Void, ?visible:Bool = true, ?color:Color):Button 
    {
        var btn:Button = new Button();
        btn.width = width;
        btn.text = text;
        btn.color = color;
        btn.onClick = onClick;
        btn.visible = visible;
        return btn;
    }

    private function buildLabel(text:String, style:Style, ?textAlign:String):Label
    {
        var label:Label = new Label();
        label.text = text;
        label.customStyle = style;
        label.textAlign = textAlign;
        return label;
    }

    private function buildRequestBox(container:VBox, questionPhrase:Phrase, onAccept:Dynamic->Void, onDecline:Dynamic->Void)
    {
        var declineBtn = constructBtnStr(ACCEPT_DECLINE_BTN_WIDTH, "✘", onDecline, Color.fromString("red"));
        var requestLabel:Label = buildLabel(Dictionary.getPhrase(questionPhrase), {}, "center");
        var acceptBtn = constructBtnStr(ACCEPT_DECLINE_BTN_WIDTH, "✔", onAccept, Color.fromString("green"));

        var requestBox:HBox = new HBox();
        requestBox.visible = false;
		requestBox.addComponent(declineBtn);
        requestBox.addComponent(requestLabel);
        requestBox.addComponent(acceptBtn);
        
        container.addComponent(requestBox);
        return requestBox;
    }
}