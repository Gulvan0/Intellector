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
import struct.ActualizationData;
import utils.TimeControl;
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
                actionBar.cancelDrawBtn.hidden = true;
                actionBar.offerDrawBtn.hidden = false;
            case TakebackOffered:
                actionBar.offerTakebackBtn.disabled = true;
                takebackRequestBox.hidden = false;
            case TakebackCancelled:
                takebackRequestBox.hidden = true;
                actionBar.offerTakebackBtn.disabled = false;
            case TakebackAccepted, TakebackDeclined:
                actionBar.cancelTakebackBtn.hidden = true;
                actionBar.offerTakebackBtn.hidden = false;
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
        whiteClock.setPlayerMove(false);
        blackClock.setPlayerMove(false);

        if (!belongsToSpectator)
            changeActionButtons([actionBar.changeOrientationBtn, actionBar.analyzeBtn, actionBar.exportSIPBtn, actionBar.rematchBtn]);
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
        var playerToMoveClock:Clock = justMovedColor == Black? whiteClock : blackClock;

        justMovedPlayerClock.stopTimer();
        justMovedPlayerClock.setPlayerMove(false);
        playerToMoveClock.setPlayerMove(true);

        if (move >= 2)
            playerToMoveClock.launchTimer();

        if (move >= 3)
            justMovedPlayerClock.addTime(secsPerTurn);

        navigator.writePlyStr(plyStr, justMovedColor);
        navigator.scrollAfterDelay();

        if (move == enableTakebackAfterMove)
            actionBar.offerTakebackBtn.disabled = false;

        if (move == 2)
        {
            actionBar.offerDrawBtn.disabled = false;
            actionBar.resignBtn.text = "⚐";
            actionBar.resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_TOOLTIP);
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
        var playerToMoveClock:Clock = justMovedColor == Black? whiteClock : blackClock;

        if (cnt % 2 == 1)
        {
            justMovedPlayerClock.stopTimer();
            justMovedPlayerClock.setPlayerMove(false);
            playerToMoveClock.setPlayerMove(true);
            playerToMoveClock.launchTimer();
        }

        if (!belongsToSpectator)
        {
            takebackRequestBox.hidden = true;
            actionBar.cancelTakebackBtn.hidden = true;
            actionBar.offerTakebackBtn.hidden = false;

            if (move < enableTakebackAfterMove)
                actionBar.offerTakebackBtn.disabled = true;

            if (move < 2)
            {
                actionBar.offerDrawBtn.disabled = true;
                actionBar.resignBtn.text = "✖";
                actionBar.resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_ABORT_TOOLTIP);
                resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);
            }
        }

        navigator.revertPlys(cnt);
        navigator.scrollAfterDelay();
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
        if (drawRequestBox.hidden)
        {
            actionBar.offerDrawBtn.hidden = true;
            actionBar.cancelDrawBtn.hidden = false;
            Networker.emitEvent(OfferDraw);
            emit(OfferDrawPressed);
        }
        else
            onAcceptDrawPressed();
    }

    private function onCancelDrawPressed()
    {
        actionBar.cancelDrawBtn.hidden = true;
        actionBar.offerDrawBtn.hidden = false;
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
            actionBar.offerTakebackBtn.hidden = true;
            actionBar.cancelTakebackBtn.hidden = false;
            emit(OfferTakebackPressed);
        }
        
        Networker.emitEvent(OfferTakeback);
    }

    private function onCancelTakebackPressed()
    {
        actionBar.offerTakebackBtn.hidden = false;
        actionBar.cancelTakebackBtn.hidden = true;
        Networker.emitEvent(CancelTakeback);
        emit(CancelTakebackPressed);
    }

    private function onAcceptTakebackPressed()
    {
        takebackRequestBox.hidden = true;
        actionBar.offerTakebackBtn.disabled = false;
        Networker.emitEvent(AcceptTakeback);
        emit(AcceptTakebackPressed);
    }

    private function onDeclineTakebackPressed()
    {
        takebackRequestBox.hidden = true;
        actionBar.offerTakebackBtn.disabled = false;
        Networker.emitEvent(DeclineTakeback);
        emit(DeclineTakebackPressed);
    }

    public static function constructFromActualizationData(data:ActualizationData, orientationColor:PieceColor, ?width:Float, ?height:Float):Sidebox
    {
        var playingAs:Null<PieceColor> = data.logParserOutput.getPlayerColor();
        var timeControl:TimeControl = data.logParserOutput.timeControl;
        var whiteLogin:String = data.logParserOutput.whiteLogin;
        var blackLogin:String = data.logParserOutput.blackLogin;

        var sidebox:Sidebox = new Sidebox(playingAs, timeControl, whiteLogin, blackLogin, orientationColor, width, height);

        var situation:Situation = Situation.starting();
        for (ply in data.logParserOutput.movesPlayed)
        {
            sidebox.makeMove(ply.toNotation(situation));
            situation = situation.makeMove(ply);
        }

        if (data.timeCorrectionData != null)
            sidebox.correctTime(data.timeCorrectionData.whiteSeconds, data.timeCorrectionData.blackSeconds, data.timeCorrectionData.timestamp, data.timeCorrectionData.pingSubtractionSide);

        return sidebox;
    }

    public function new(playingAs:Null<PieceColor>, timeControl:TimeControl, whiteLogin:String, blackLogin:String, orientationColor:PieceColor, ?width:Float, ?height:Float) 
    {
        super();
        this.belongsToSpectator = playingAs == null;
        this.secsPerTurn = timeControl.bonusSecs;
        this.orientationColor = White;
        this.move = 0;
        this.resignConfirmationMessage = Dictionary.getPhrase(ABORT_CONFIRMATION_MESSAGE);

        if (playingAs != null)
            enableTakebackAfterMove = playingAs == White? 1 : 2;
        
        whiteClock.init(timeControl.startSecs, playingAs == White, timeControl.startSecs >= 90, true);
        blackClock.init(timeControl.startSecs, playingAs == Black, timeControl.startSecs >= 90, false);

        whiteLoginLabel.text = whiteLogin;
        blackLoginLabel.text = blackLogin;

        actionBar.changeOrientationBtn.onClick = revertOrientation.expand();
        actionBar.resignBtn.onClick = onResignPressed.expand();
        actionBar.offerDrawBtn.onClick = onOfferDrawPressed.expand();
        actionBar.cancelDrawBtn.onClick = onCancelDrawPressed.expand();
        actionBar.addTimeBtn.onClick = Networker.emitEvent.bind(AddTime).expand();
        actionBar.offerTakebackBtn.onClick = onOfferTakebackPressed.expand();
        actionBar.cancelTakebackBtn.onClick = onCancelTakebackPressed.expand();
        actionBar.rematchBtn.onClick = emit.bind(RematchRequested).expand();
        actionBar.exportSIPBtn.onClick = emit.bind(ExportSIPRequested).expand();
        actionBar.analyzeBtn.onClick = emit.bind(ExploreInAnalysisRequest).expand();
        declineDrawBtn.onClick = onDeclineDrawPressed.expand();
        acceptDrawBtn.onClick = onAcceptDrawPressed.expand();
        declineTakebackBtn.onClick = onDeclineTakebackPressed.expand();
        acceptTakebackBtn.onClick = onAcceptTakebackPressed.expand();
        
        var explicitNavigatorHeight:Null<Float> = null;
        if (height != null)
            explicitNavigatorHeight = height - blackClock.height - blackLoginCard.height - specialBox.height - whiteLoginCard.height - whiteClock.height;
        if (width != null)
            this.width = width;
        navigator.init(type -> {emit(PlyScrollRequest(type));}, width, explicitNavigatorHeight);

        if (belongsToSpectator)
            changeActionButtons([actionBar.changeOrientationBtn, actionBar.analyzeBtn, actionBar.exportSIPBtn]);
        else
            changeActionButtons([actionBar.changeOrientationBtn, actionBar.offerDrawBtn, actionBar.offerTakebackBtn, actionBar.resignBtn, actionBar.addTimeBtn]);

        if (orientationColor == Black)
            revertOrientation();
    }
}