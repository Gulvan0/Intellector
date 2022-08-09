package gfx.game;

import net.ServerEvent;
import gameboard.GameBoard.GameBoardEvent;
import gameboard.GameBoard.IGameBoardObserver;
import net.EventProcessingQueue.INetObserver;
import struct.PieceColor;
import net.LoginManager;
import openfl.events.Event;
import haxe.ui.containers.Box;
import haxe.Timer;
import openfl.Assets;
import haxe.ui.styles.Style;
import haxe.ui.containers.Card;
import utils.TimeControl;
import haxe.ui.components.Label;
import haxe.ui.macros.ComponentMacros;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/clock.xml"))
class Clock extends Card implements INetObserver implements IGameBoardObserver
{
    private var playSoundOnOneMinuteLeft:Bool;
    private var alertsEnabled:Bool;

    private var secondsLeftAtReliableTimestamp:Float;
    private var reliableTimestamp:Float;
    private var running:Bool = false;

    private var active:Bool;
    private var ownerColor:PieceColor;
    private var ownerToMove:Bool;
    private var moveNum:Int;
    private var secondsLeft:Float;

    //TODO: Do it properly
    public function resize(newHeight:Float)
    {
        var unit:Float = newHeight / 11;

        var newLabelStyle = label.customStyle.clone();
        newLabelStyle.fontSize = 9.6 * unit;
        label.customStyle = newLabelStyle;

        var newCardStyle = this.customStyle.clone();
        newCardStyle.paddingTop = unit;
        newCardStyle.paddingBottom = unit;
        newCardStyle.paddingLeft = 4 * unit;
        newCardStyle.paddingRight = 4 * unit;
        this.customStyle = newCardStyle;
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case TimeCorrection(whiteSeconds, blackSeconds, timestamp):
                correctTime(whiteSeconds, blackSeconds, timestamp);
            case Move(fromI, toI, fromJ, toJ, morphInto, whiteSeconds, blackSeconds, timestamp):
                correctTime(whiteSeconds, blackSeconds, timestamp);
                moveNum++;
                toggleTurnColor();
            case Rollback(plysToUndo, whiteSeconds, blackSeconds, timestamp):
                correctTime(whiteSeconds, blackSeconds, timestamp);
                moveNum -= plysToUndo;
                if (plysToUndo % 2 == 1)
                    toggleTurnColor();
            case GameEnded(winner_color, reason, whiteSecondsRemainder, blackSecondsRemainder):
                active = false;
                pauseTimer();
                correctTime(whiteSecondsRemainder, blackSecondsRemainder, Date.now().getTime());
                refreshColoring();
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event 
        {
            case ContinuationMove(_, _, _):
                moveNum++;
                toggleTurnColor();
            default:
        }
    }

    private function refreshColoring()
    {
        var backgroundColor:Int = -1;
        var textColor:Int = -1;
        var lowTime:Bool = alertsEnabled && secondsLeft < 60;

        if (active && ownerToMove && lowTime)
        {
            backgroundColor = 0xffbbbb;
            textColor = 0xaa0000;
        }
        else if (active && ownerToMove && !lowTime)
        {
            backgroundColor = 0xd5e5d3;
            textColor = 0x000000;
        }
        else if (active && !ownerToMove && lowTime)
        {
            backgroundColor = 0xffdddd;
            textColor = 0x666666;
        }
        else
        {
            backgroundColor = 0xffffff;
            textColor = 0x666666;
        }

        var newLabelStyle = label.customStyle.clone();
        newLabelStyle.color = textColor;
        label.customStyle = newLabelStyle;

        var newCardStyle = this.customStyle.clone();
        newCardStyle.backgroundColor = backgroundColor;
        this.customStyle = newCardStyle;
    }

    private function updateTimeLeft(?e) 
    {

        if (running)
            secondsLeft = Math.max(secondsLeftAtReliableTimestamp - (Date.now().getTime() - reliableTimestamp) / 1000, 0);
        else
            secondsLeft = secondsLeftAtReliableTimestamp;

        label.text = TimeControl.secsToString(secondsLeft);

        if (secondsLeft == 0)
        {
            removeEventListener(Event.ENTER_FRAME, updateTimeLeft);
            running = false;
            Networker.emitEvent(RequestTimeoutCheck);
        }

        if (alertsEnabled)
        {
            refreshColoring();

            if (secondsLeft < 60 && playSoundOnOneMinuteLeft)
            {
                Assets.getSound("sounds/lowtime.mp3").play();
                playSoundOnOneMinuteLeft = false;
            }
        }
    }

    private function launchTimer()
    {
        addEventListener(Event.ENTER_FRAME, updateTimeLeft);
        running = true;
    }

    private function pauseTimer() 
    {
        removeEventListener(Event.ENTER_FRAME, updateTimeLeft);
        running = false;
    }

    private function correctTime(whiteSeconds:Float, blackSeconds:Float, validAt:Float) 
    {
        secondsLeftAtReliableTimestamp = ownerColor == White? whiteSeconds : blackSeconds;
        reliableTimestamp = validAt;
        updateTimeLeft();
    }

    private function toggleTurnColor()
    {
        ownerToMove = !ownerToMove;
        refreshColoring();

        if (moveNum >= 2 && ownerToMove)
            launchTimer();
        else if (moveNum > 2 && !ownerToMove)
            pauseTimer();
    }

    public function init(constructor:LiveGameConstructor, ownerColor:PieceColor)
    {
        this.ownerColor = ownerColor;
        switch constructor 
        {
            case New(whiteLogin, blackLogin, timeControl, startingSituation, _):
                this.playSoundOnOneMinuteLeft = timeControl.startSecs >= 90;
                this.alertsEnabled = LoginManager.isPlayer(ownerColor == White? whiteLogin : blackLogin);
                this.active = true;
                this.ownerToMove = startingSituation.turnColor == ownerColor;
                this.moveNum = 0;
                this.secondsLeft = timeControl.startSecs;

                label.text = TimeControl.secsToString(timeControl.startSecs);
            case Ongoing(parsedData, whiteSeconds, blackSeconds, timeValidAtTimestamp, _):
                var startSecs:Int = parsedData.timeControl.startSecs;

                this.playSoundOnOneMinuteLeft = startSecs >= 90;
                this.alertsEnabled = parsedData.getPlayerColor() == ownerColor;
                this.active = true;
                this.ownerToMove = parsedData.currentSituation.turnColor == ownerColor;
                this.moveNum = parsedData.moveCount;

                correctTime(whiteSeconds, blackSeconds, timeValidAtTimestamp);
                if (ownerToMove && (moveNum >= 2 || secondsLeft != startSecs)) //The last condition is a somewhat (i. e., unless float ownerSecsLeft will miraclously match integer startSecs) reliable workaround for cases when the first two moves had been made, but then, due to takebacks, the total move count became less than 2 once again (and then the reconnection happened)
                    launchTimer();

            case Past(parsedData):
                this.active = false;
                if (parsedData.msLeftWhenEnded != null)
                    label.text = TimeControl.secsToString(parsedData.msLeftWhenEnded[ownerColor] * 1000);
                else
                    hidden = true;
        }
    }
    
    public function new()
    {
        super();
    }
}