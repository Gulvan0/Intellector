package gfx.game;

import net.shared.dataobj.TimeReservesData;
import net.shared.ServerEvent;
import gameboard.GameBoard.GameBoardEvent;
import gameboard.GameBoard.IGameBoardObserver;
import net.EventProcessingQueue.INetObserver;
import net.shared.PieceColor;
import assets.Audio;
import haxe.ui.containers.Box;
import haxe.Timer;
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

    private var invisible:Bool = false;

    private var timer:Timer;

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

    public function setTimeManually(secondsLeft:Float)
    {
        if (active)
            throw "You can only set time manually for inactive clocks. For active clocks, it is set as a result of processing the corresponding events";

        label.text = TimeControl.secsToString(secondsLeft);
    }

    public function handleNetEvent(event:ServerEvent)
    {
        if (!active)
            return;

        switch event 
        {
            case TimeCorrection(timeData):
                correctTime(timeData);
            case Move(_, timeData):
                if (timeData != null)
                    correctTime(timeData);
                moveNum++;
                toggleTurnColor();
            case Rollback(plysToUndo, timeData):
                correctTime(timeData);
                moveNum -= plysToUndo;
                if (plysToUndo % 2 == 1)
                    toggleTurnColor();
            case TimeAdded(_, timeData):
                correctTime(timeData);
            case GameEnded(_, _, remainingTimeMs, _):
                active = false;
                pauseTimer();
                if (remainingTimeMs != null)
                    label.text = TimeControl.secsToString(remainingTimeMs[ownerColor] / 1000);
                refreshColoring();
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        if (!active)
            return;

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

    private function updateTimeLeft() 
    {
        if (running)
            secondsLeft = Math.max(secondsLeftAtReliableTimestamp - (Date.now().getTime() - reliableTimestamp) / 1000, 0);
        else
            secondsLeft = secondsLeftAtReliableTimestamp;

        if (label != null)
            label.text = TimeControl.secsToString(secondsLeft);
        else
            return;

        if (secondsLeft == 0)
        {
            if (timer != null)
                timer.stop();
            running = false;
        }

        if (alertsEnabled)
        {
            refreshColoring();

            if (secondsLeft < 60 && playSoundOnOneMinuteLeft)
            {
                Audio.playSound("lowtime");
                playSoundOnOneMinuteLeft = false;
            }
        }
    }

    private function launchTimer()
    {
        timer = new Timer(10);
        timer.run = updateTimeLeft;
        running = true;
    }

    private function pauseTimer() 
    {
        if (timer != null)
            timer.stop();
        running = false;
    }

    public function deactivate()
    {
        active = false;
        pauseTimer();
    }

    private function correctTime(timeData:TimeReservesData) 
    {
        secondsLeftAtReliableTimestamp = ownerColor == White? timeData.whiteSeconds : timeData.blackSeconds;
        reliableTimestamp = timeData.timestamp;
        updateTimeLeft();
    }

    private function initTime(timeControlStartSecs:Int, startDatetime:Date)
    {
        secondsLeftAtReliableTimestamp = timeControlStartSecs;
        reliableTimestamp = startDatetime.getTime();
        label.text = TimeControl.secsToString(timeControlStartSecs);
        secondsLeft = timeControlStartSecs;
    }

    private function toggleTurnColor()
    {
        ownerToMove = !ownerToMove;
        refreshColoring();

        if (moveNum >= 2 && ownerToMove)
            launchTimer();
        else if (!ownerToMove)
            pauseTimer();
    }

    public function init(constructor:LiveGameConstructor, ownerColor:PieceColor)
    {
        this.ownerColor = ownerColor;
        switch constructor 
        {
            case New(whiteRef, blackRef, _, timeControl, startingSituation, startDatetime):
                if (timeControl.getType() == Correspondence)
                {
                    this.active = false;
                    hidden = true;
                    invisible = true;
                    return;
                }

                this.playSoundOnOneMinuteLeft = timeControl.startSecs >= 90;
                this.alertsEnabled = LoginManager.isPlayer(ownerColor == White? whiteRef : blackRef);
                this.active = true;
                this.ownerToMove = startingSituation.turnColor == ownerColor;
                this.moveNum = 0;

                initTime(timeControl.startSecs, startDatetime);

            case Ongoing(parsedData, timeData, _):
                if (parsedData.timeControl.getType() == Correspondence)
                {
                    this.active = false;
                    hidden = true;
                    invisible = true;
                    return;
                }

                var startSecs:Int = parsedData.timeControl.startSecs;

                this.playSoundOnOneMinuteLeft = startSecs >= 90;
                this.alertsEnabled = parsedData.getPlayerColor() == ownerColor;
                this.active = true;
                this.ownerToMove = parsedData.currentSituation.turnColor == ownerColor;
                this.moveNum = parsedData.moveCount;

                if (timeData != null)
                    correctTime(timeData);
                else
                    initTime(startSecs, parsedData.datetime);

                if (ownerToMove && (moveNum >= 2 || secondsLeft != startSecs)) //The last condition is a somewhat (i. e., unless float ownerSecsLeft will miraclously match integer startSecs) reliable workaround for cases when the first two moves had been made, but then, due to takebacks, the total move count became less than 2 once again (and then the reconnection happened)
                    launchTimer();

            case Past(parsedData, _):
                this.active = false;
                if (parsedData.msLeftWhenEnded != null)
                    label.text = TimeControl.secsToString(parsedData.msLeftWhenEnded[ownerColor] / 1000);
                else
                    hidden = true;
        }
    }

    public override function set_hidden(v:Bool):Bool
    {
        if (!invisible)
            return super.set_hidden(v);
        else
            return v;
    }
    
    public function new()
    {
        super();
    }
}