package gfx.live.live;

import haxe.ui.core.Component;
import gfx.live.interfaces.IReadOnlyMsRemainders;
import gfx.live.interfaces.IGameComponentObserver;
import gfx.live.events.ModelUpdateEvent;
import gfx.live.models.ReadOnlyModel;
import gfx.live.interfaces.IGameComponent;
import net.shared.dataobj.TimeReservesData;
import net.shared.ServerEvent;
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

using gfx.live.models.CommonModelExtractors;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/clock.xml"))
class Clock extends Card implements IGameComponent
{
    private var playSoundOnOneMinuteLeft:Bool;
    private var alertsEnabled:Bool;

    private var secondsLeftAtReliableTimestamp:Float;
    private var reliableTimestamp:Float;
    private var running:Bool = false;

    private var active:Bool;
    private var ownerColor:PieceColor;
    private var ownerToMove:Bool;
    private var secondsLeft:Float;

    private var invisible:Bool = false;

    private var timer:Timer;

    public function init(model:ReadOnlyModel, gameScreen:IGameComponentObserver)
    {
        if (model.gameEnded())
        {
            this.active = false;
            setTimeToAmountLeftWhenEnded(model.getMsRemainders());
        }
        else
        {
            this.active = true;

            var timeControl = model.getTimeControl();

            if (timeControl == null || timeControl.isCorrespondence())
                throw "Cannot create clock: no allowed time control present";

            this.playSoundOnOneMinuteLeft = timeControl.startSecs >= 90;
            this.alertsEnabled = model.playerColor() == ownerColor;

            correctTime(model.timeData());
            onActiveTimerColorUpdated(model.activeTimerColor());
        }
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        switch event 
        {
            case GameEnded:
                onGameEnded(model.getMsRemainders());
            case ViewedMoveNumUpdated:
                if (model.gameEnded())
                {
                    var shownMovePointer:Int = model.getShownMovePointer();
                    if (shownMovePointer == model.getLineLength())
                        setTimeToAmountLeftWhenEnded(model.getMsRemainders());
                    else
                        label.text = TimeControl.secsToString(model.getMsRemainders().getSecsLeftAfterMove(ownerColor, shownMovePointer));
                }
            case TimeDataUpdated:
                correctTime(model.timeData());
            case ActiveTimerColorUpdated:
                onActiveTimerColorUpdated(model.activeTimerColor());
            default:
        }
    }

    private function setTimeToAmountLeftWhenEnded(msRemainders:IReadOnlyMsRemainders)
    {
        var remainingSecs:Null<Float> = msRemainders.getSecsLeftWhenEnded(ownerColor);
        
        if (remainingSecs != null)
            label.text = TimeControl.secsToString(remainingSecs);
    }

    private function onGameEnded(msRemainders:IReadOnlyMsRemainders)
    {
        active = false;
        pauseTimer();
        setTimeToAmountLeftWhenEnded(msRemainders);
        refreshColoring();
    }

    private function onActiveTimerColorUpdated(activeTimerColor:Null<PieceColor>)
    {
        ownerToMove = (activeTimerColor == ownerColor);
        refreshColoring();

        if (ownerToMove)
            launchTimer();
        else if (!ownerToMove)
            pauseTimer();
    }

    public function destroy()
    {
        pauseTimer();
    }

    public function asComponent():Component
    {
        return this;
    }

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

    private function correctTime(timeData:TimeReservesData) 
    {
        secondsLeftAtReliableTimestamp = ownerColor == White? timeData.whiteSeconds : timeData.blackSeconds;
        reliableTimestamp = timeData.timestamp;
        updateTimeLeft();
    }

    public function new(ownerColor:PieceColor)
    {
        super();
        this.ownerColor = ownerColor;
    }
}