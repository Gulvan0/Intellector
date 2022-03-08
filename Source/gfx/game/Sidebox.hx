package gfx.game;

import gfx.common.Clock;
import dict.Phrase;
import gfx.utils.PlyScrollType;
import gfx.common.MoveNavigator;
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

enum SideboxEvent
{
    ChangeOrientationPressed;
    ResignPressed;
    OfferDrawPressed;
    CancelDrawPressed;
    AcceptDrawPressed;
    DeclineDrawPressed;
    OfferTakebackPressed;
    CancelTakebackPressed;
    AcceptTakebackPressed;
    DeclineTakebackPressed;
    RematchRequested;
    ExportSIPRequested;
    ExploreInAnalysisRequest;
    PlyScrollRequest(type:PlyScrollType);
}

interface ISideboxObserver 
{
    public function handleSideboxEvent(event:SideboxEvent):Void;    
}

@:build(haxe.ui.macros.ComponentMacros.build("layouts/sidebox.xml"))
class Sidebox extends VBox
{
    private var belongsToSpectator:Bool;
    private var orientationColor:PieceColor;
    private var move:Int;

    private var secsPerTurn:Int;
    private var lastMovetableEntry:Dynamic;

    private var observers:Array<ISideboxObserver> = [];

    public function addObserver(obs:ISideboxObserver) 
    {
        observers.push(obs);
    }

    public function removeObserver(obs:ISideboxObserver) 
    {
        observers.remove(obs);
    }

    public function emit(event:SideboxEvent) 
    {
        for (obs in observers)
            obs.handleSideboxEvent(event);
    }

    private function changeActionButtons(shownButtons:Array<Button>)
    {
        actionBar.walkComponents(c -> {c.hidden = true;});

        var widthStyle:Style = {percentWidth: 100 / shownButtons.length};
        for (btn in shownButtons)
        {
            btn.applyStyle(widthStyle);
            btn.hidden = false;
        }
    }

    public function correctTime(correctedSecsWhite:Float, correctedSecsBlack:Float, actualTimestamp:Float) 
    {
        whiteClock.correctTime(correctedSecsWhite, actualTimestamp);
        blackClock.correctTime(correctedSecsBlack, actualTimestamp);
    }

    private function revertOrientation()
    {
        removeComponent(whiteClock);
        removeComponent(blackClock);

        orientationColor = opposite(orientationColor);

        var upperClock:Clock = orientationColor == White? blackClock : whiteClock;
        var bottomClock:Clock = orientationColor == White? whiteClock : blackClock;

        addComponentAt(upperClock, 0);
        addComponent(bottomClock);

        emit(ChangeOrientationPressed);
    }

    public function onGameEnded() 
    {
        upperTime.stopTimer();
        bottomTime.stopTimer();

        if (!belongsToSpectator)
            changeActionButtons([changeOrientationBtn, analyzeBtn, exportSIPBtn, rematchBtn]);
    }

    //=====================================================================================================================
    //TODO: Rewrite this section + makeMove + revertPlys

    public function scrollAfterDelay() 
    {
        Timer.delay(scrollToEnd, 100);
    }

    public function scrollToEnd() 
    {
        var vscroll = movetable.findComponent(VerticalScroll, false);
        if (vscroll != null)
            vscroll.pos = vscroll.max;
    }

    public function writePlyStr(plyStr:String, performedBy:PieceColor)
    {
        if (performedBy == Black)
            if (plyNumber == 1)
            {
                lastMovetableEntry = {"num": '1', "white_move": "", "black_move": plyStr};
                movetable.dataSource.add(lastMovetableEntry);
            }
            else
            {
                lastMovetableEntry.black_move = plyStr;
                movetable.dataSource.update(movetable.dataSource.size - 1, lastMovetableEntry);
            }
        else 
        {
            lastMovetableEntry = {"num": '$plyNumber', "white_move": plyStr, "black_move": " "};
            movetable.dataSource.add(lastMovetableEntry);
        }

        plyNumber++;
    }

    public function writePly(ply:Ply, contextSituation:Situation) 
    {
        var plyStr = ply.toNotation(contextSituation);
        var performedBy = contextSituation.turnColor;
        writePlyStr(plyStr, performedBy);
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

    public function init(belongsToSpectator:Bool, startSecs:Int, secsPerTurn:Int, whiteLogin:String, blackLogin:String, orientationColor:PieceColor) 
    {
        this.belongsToSpectator = belongsToSpectator;
        this.secsPerTurn = secsPerTurn;
        this.orientationColor = orientationColor;
        this.move = 1; //TODO: Change to zero?
        
        whiteClock.init(startSecs, false, startSecs >= 90);
        bottomTime.init(startSecs, !belongsToSpectator, startSecs >= 90);

        whiteLoginLabel.text = whiteLogin;
        blackLoginLabel.text = blackLogin;

        changeOrientationBtn.onClick = revertOrientation.expand();
        resignBtn.onClick = emit.bind(ResignPressed).expand();
        offerDrawBtn.onClick = emit.bind(OfferDrawPressed).expand();
        cancelDrawBtn.onClick = emit.bind(CancelDrawPressed).expand();
        addTimeBtn.onClick = Networker.emitEvent.bind(AddTime).expand();
        offerTakebackBtn.onClick = emit.bind(OfferDrawPressed).expand();
        cancelTakebackBtn.onClick = emit.bind(CancelDrawPressed).expand();
        rematchBtn.onClick = emit.bind(CancelDrawPressed).expand();
        exportSIPBtn.onClick = emit.bind(ExportSIPRequested).expand();
        analyzeBtn.onClick = emit.bind(ExploreInAnalysisRequest).expand();
        declineDrawBtn.onClick = emit.bind(DeclineDrawPressed).expand();
        acceptDrawBtn.onClick = emit.bind(AcceptDrawPressed).expand();
        declineTakebackBtn.onClick = emit.bind(DeclineTakebackPressed).expand();
        acceptTakebackBtn.onClick = emit.bind(AcceptTakebackPressed).expand();
        
        navigator.init(type -> {emit(PlyScrollRequest(type));});

        if (belongsToSpectator)
            changeActionButtons([changeOrientationBtn, analyzeBtn, exportSIPBtn]);
        else
            changeActionButtons([changeOrientationBtn, offerDrawBtn, offerTakebackBtn, resignBtn, addTimeBtn]);

        if (orientationColor == Black)
            revertOrientation(null);
    }
    
    public function new()
    {
        super();
    }
}