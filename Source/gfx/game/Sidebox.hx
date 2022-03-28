package gfx.game;

import gameboard.GameBoard.GameBoardEvent;
import gameboard.GameBoard.IGameBoardObserver;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import net.EventProcessingQueue.INetObserver;
import net.ServerEvent;
import gfx.common.Clock;
import haxe.ui.containers.Card;
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
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import haxe.ui.containers.TableView;
import haxe.ui.components.Label;
import openfl.display.Sprite;
using utils.CallbackTools;

enum SideboxEvent
{
    ChangeOrientationPressed;
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

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/sidebox.xml'))
class Sidebox extends VBox implements INetObserver implements IGameBoardObserver
{
    private var resignConfirmationMessage:String;

    private var enableTakebackAfterMove:Int;
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

    private function emit(event:SideboxEvent) 
    {
        for (obs in observers)
            obs.handleSideboxEvent(event);
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case TimeCorrection(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide):
                correctTime(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide);
            case GameEnded(winner_color, reason):
                onGameEnded();
            case Rollback(plysToUndo):
                revertPlys(plysToUndo);
            case DrawOffered:
                drawRequestBox.hidden = false;
            case DrawCancelled:
                drawRequestBox.hidden = true;
            case DrawAccepted, DrawDeclined:
                cancelDrawBtn.hidden = true;
                offerDrawBtn.hidden = false;
            case TakebackOffered:
                takebackRequestBox.hidden = false;
            case TakebackCancelled:
                takebackRequestBox.hidden = true;
            case TakebackAccepted, TakebackDeclined:
                cancelTakebackBtn.hidden = true;
                offerTakebackBtn.hidden = false;
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event 
        {
            case ContinuationMove(ply, plyStr, performedBy):
                makeMove(plyStr);
            default:
        }
    }

    private function actualize(movesPlayed:Array<Ply>)
    {
        var situation:Situation = Situation.starting();
        for (ply in movesPlayed)
        {
            makeMove(ply.toNotation(situation));
            situation = situation.makeMove(ply);
        }
    }

    private function correctTime(whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String)
    {
        var currentTimestamp:Float = Date.now().getTime();
        var halfPing:Float = currentTimestamp - timestamp;

        if (pingSubtractionSide == "w")
            whiteSeconds -= halfPing / 1000;
        else if (pingSubtractionSide == "b")
            blackSeconds -= halfPing / 1000;

        whiteClock.correctTime(whiteSeconds, currentTimestamp);
        blackClock.correctTime(blackSeconds, currentTimestamp);
    }

    private function onGameEnded()
    {
        whiteClock.stopTimer();
        blackClock.stopTimer();

        if (!belongsToSpectator)
            changeActionButtons([changeOrientationBtn, analyzeBtn, exportSIPBtn, rematchBtn]);
    }

    //===========================================================================================================================================================

    private function changeActionButtons(shownButtons:Array<Button>)
    {
        for (i in 0...actionBar.numComponents)
            actionBar.getComponentAt(i).hidden = true;

        var btnWidth:Float = 100 / shownButtons.length;
        for (btn in shownButtons)
        {
            btn.hidden = false;
            btn.percentWidth = btnWidth;
        }
    }

    private function revertOrientation()
    {
        removeComponent(whiteClock, false);
        removeComponent(blackClock, false);
        removeComponent(whiteLoginCard, false);
        removeComponent(blackLoginCard, false);

        orientationColor = opposite(orientationColor);

        var upperClock:Clock = orientationColor == White? blackClock : whiteClock;
        var bottomClock:Clock = orientationColor == White? whiteClock : blackClock;
        var upperLogin:Card = orientationColor == White? blackLoginCard : whiteLoginCard;
        var bottomLogin:Card = orientationColor == White? whiteLoginCard : blackLoginCard;

        addComponentAt(upperLogin, 0);
        addComponentAt(upperClock, 0);

        addComponent(bottomLogin);
        addComponent(bottomClock);

        emit(ChangeOrientationPressed);
    }

    //========================================================================================================================================================================

    public function makeMove(plyStr:String) 
    {
        move++;

        var justMovedColor:PieceColor = move % 2 == 1? White : Black;
        var justMovedPlayerClock:Clock = justMovedColor == White? whiteClock : blackClock;
        var playerToMoveClock:Clock = justMovedColor == Black? blackClock : whiteClock;

        justMovedPlayerClock.stopTimer();

        if (move >= 2)
            playerToMoveClock.launchTimer();

        if (move >= 3)
            justMovedPlayerClock.addTime(secsPerTurn);

        navigator.writePlyStr(plyStr, justMovedColor);
        navigator.scrollAfterDelay();

        if (move == enableTakebackAfterMove)
            offerTakebackBtn.disabled = false;

        if (move == 2)
        {
            offerDrawBtn.disabled = false;
            resignBtn.text = "⚐";
            resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_TOOLTIP);
            resignConfirmationMessage = Dictionary.getPhrase(RESIGN_CONFIRMATION_MESSAGE);
        }
    }

    private function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        move -= cnt;

        var justMovedColor:PieceColor = move % 2 == 1? White : Black;
        var justMovedPlayerClock:Clock = justMovedColor == White? whiteClock : blackClock;
        var playerToMoveClock:Clock = justMovedColor == Black? blackClock : whiteClock;

        if (cnt % 2 == 1)
        {
            justMovedPlayerClock.stopTimer();
            playerToMoveClock.launchTimer();
        }

        if (!belongsToSpectator)
        {
            takebackRequestBox.hidden = true;
            cancelTakebackBtn.hidden = true;
            offerTakebackBtn.hidden = false;

            if (move < enableTakebackAfterMove)
                offerTakebackBtn.disabled = true;

            if (move < 2)
            {
                offerDrawBtn.disabled = true;
                resignBtn.text = "✖";
                resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_ABORT_TOOLTIP);
                resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);
            }
        }

        navigator.revertPlys(cnt);
    }

    //==================================================================================================================================================

    private function onResignPressed()
    {
        var confirmed:Bool = Browser.window.confirm(resignConfirmationMessage);
        if (confirmed)
            Networker.emitEvent(Resign);
    }

    private function onOfferDrawPressed()
    {
        offerDrawBtn.hidden = true;
        cancelDrawBtn.hidden = false;
        Networker.emitEvent(OfferDraw);
        emit(OfferDrawPressed);
    }

    private function onCancelDrawPressed()
    {
        cancelDrawBtn.hidden = true;
        offerDrawBtn.hidden = false;
        Networker.emitEvent(CancelDraw);
        emit(CancelDrawPressed);
    }

    private function onAcceptDrawPressed()
    {
        drawRequestBox.hidden = true;
        Networker.emitEvent(AcceptDraw);
        emit(AcceptDrawPressed);
    }

    private function onDeclineDrawPressed()
    {
        drawRequestBox.hidden = true;
        Networker.emitEvent(DeclineDraw);
        emit(DeclineDrawPressed);
    }

    private function onOfferTakebackPressed()
    {
        if (!takebackRequestBox.hidden)
        {
            takebackRequestBox.hidden = true;
            emit(AcceptTakebackPressed);
        }
        else
        {
            offerTakebackBtn.hidden = true;
            cancelTakebackBtn.hidden = false;
            emit(OfferTakebackPressed);
        }
        
        Networker.emitEvent(OfferTakeback);
    }

    private function onCancelTakebackPressed()
    {
        offerTakebackBtn.hidden = false;
        cancelTakebackBtn.hidden = true;
        Networker.emitEvent(CancelTakeback);
        emit(CancelTakebackPressed);
    }

    private function onAcceptTakebackPressed()
    {
        takebackRequestBox.hidden = true;
        Networker.emitEvent(AcceptTakeback);
        emit(AcceptTakebackPressed);
    }

    private function onDeclineTakebackPressed()
    {
        takebackRequestBox.hidden = true;
        Networker.emitEvent(DeclineTakeback);
        emit(DeclineTakebackPressed);
    }

    public function new(playingAs:Null<PieceColor>, startSecs:Int, secsPerTurn:Int, whiteLogin:String, blackLogin:String, orientationColor:PieceColor, ?actualizationData:GameLogParserOutput) 
    {
        super();
        this.belongsToSpectator = playingAs == null;
        this.secsPerTurn = secsPerTurn;
        this.orientationColor = White;
        this.move = 0;
        this.resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);

        if (playingAs != null)
            enableTakebackAfterMove = playingAs == White? 1 : 2;
        
        whiteClock.init(startSecs, false, startSecs >= 90);
        blackClock.init(startSecs, !belongsToSpectator, startSecs >= 90);

        whiteLoginLabel.text = whiteLogin;
        blackLoginLabel.text = blackLogin;

        changeOrientationBtn.onClick = revertOrientation.expand();
        resignBtn.onClick = onResignPressed.expand();
        offerDrawBtn.onClick = onOfferDrawPressed.expand();
        cancelDrawBtn.onClick = onCancelDrawPressed.expand();
        addTimeBtn.onClick = Networker.emitEvent.bind(AddTime).expand();
        offerTakebackBtn.onClick = onOfferTakebackPressed.expand();
        cancelTakebackBtn.onClick = onCancelTakebackPressed.expand();
        rematchBtn.onClick = emit.bind(RematchRequested).expand();
        exportSIPBtn.onClick = emit.bind(ExportSIPRequested).expand();
        analyzeBtn.onClick = emit.bind(ExploreInAnalysisRequest).expand();
        declineDrawBtn.onClick = onDeclineDrawPressed.expand();
        acceptDrawBtn.onClick = onAcceptDrawPressed.expand();
        declineTakebackBtn.onClick = onDeclineTakebackPressed.expand();
        acceptTakebackBtn.onClick = onAcceptTakebackPressed.expand();
        
        navigator.init(type -> {emit(PlyScrollRequest(type));});

        if (belongsToSpectator)
            changeActionButtons([changeOrientationBtn, analyzeBtn, exportSIPBtn]);
        else
            changeActionButtons([changeOrientationBtn, offerDrawBtn, offerTakebackBtn, resignBtn, addTimeBtn]);

        if (orientationColor == Black)
            revertOrientation();

        if (actualizationData != null)
            actualize(actualizationData.movesPlayed);
    }
}