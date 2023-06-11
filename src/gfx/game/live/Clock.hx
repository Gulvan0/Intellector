package gfx.game.live;

import gfx.game.interfaces.IGameScreenGetters;
import haxe.ui.events.UIEvent;
import net.shared.utils.UnixTimestamp;
import gfx.game.interfaces.IReadOnlyGameRelatedModel;
import haxe.ui.core.Component;
import gfx.game.interfaces.IReadOnlyMsRemainders;
import gfx.game.interfaces.IBehaviour;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IGameComponent;
import net.shared.dataobj.TimeReservesData;
import net.shared.ServerEvent;
import net.INetObserver;
import net.shared.PieceColor;
import assets.Audio;
import haxe.ui.containers.Box;
import haxe.Timer;
import haxe.ui.styles.Style;
import haxe.ui.containers.Card;
import net.shared.TimeControl;
import haxe.ui.components.Label;
import haxe.ui.macros.ComponentMacros;

using gfx.game.models.CommonModelExtractors;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/live/clock.xml"))
class Clock extends Box implements IGameComponent
{
    private var playSoundOnOneMinuteLeft:Bool;
    private var alertsEnabled:Bool;

    private var secondsLeftAtReliableTimestamp:Float;
    private var reliableTimestamp:UnixTimestamp;
    private var running:Bool = false;

    private var active:Bool;
    private var ownerColor:PieceColor;
    private var ownerToMove:Bool;
    private var secondsLeft:Float;

    private var invisible:Bool = false;

    private var timer:Timer;

    public function init(model:ReadOnlyModel, getters:IGameScreenGetters)
    {
        var gameModel:IReadOnlyGameRelatedModel = model.asGameModel();

        if (gameModel.hasEnded())
        {
            active = false;
            setTimeToAmountLeftWhenEnded(gameModel.getMsRemainders());
        }
        else
        {
            active = true;

            var timeControl = gameModel.getTimeControl();

            if (timeControl == null || timeControl.isCorrespondence())
                throw "Cannot create clock: no allowed time control present";

            playSoundOnOneMinuteLeft = timeControl.startSecs >= 90;
            alertsEnabled = gameModel.getPlayerColor() == ownerColor;

            onActiveTimerColorUpdated(gameModel.getActiveTimerColor());
            var timeReserves:TimeReservesData = gameModel.getActualTimeReserves();
            correctTime(timeReserves.getSecsLeftAtTimestamp(ownerColor), timeReserves.timestamp);
        }
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        var gameModel:IReadOnlyGameRelatedModel = model.asGameModel();
        
        switch event 
        {
            case GameEnded:
                onGameEnded(gameModel.getMsRemainders());
            case ViewedMoveNumUpdated:
                if (gameModel.hasEnded())
                {
                    var shownMovePointer:Int = gameModel.getShownMovePointer();
                    if (shownMovePointer == gameModel.getLineLength())
                        setTimeToAmountLeftWhenEnded(gameModel.getMsRemainders());
                    else
                        label.text = TimeControl.secsToString(gameModel.getMsRemainders().getTimeLeftAt(shownMovePointer).getSecsLeftAtTimestamp(ownerColor));
                }
            case TimeDataUpdated:
                var timeReserves:TimeReservesData = gameModel.getActualTimeReserves();
                correctTime(timeReserves.getSecsLeftAtTimestamp(ownerColor), timeReserves.timestamp);
                onActiveTimerColorUpdated(gameModel.getActiveTimerColor());
            default:
        }
    }

    private function setTimeToAmountLeftWhenEnded(msRemainders:IReadOnlyMsRemainders)
    {
        var remainingSecs:Null<Float> = msRemainders.getTimeLeftWhenEnded().getSecsLeftAtTimestamp(ownerColor);
        
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

    @:bind(this, UIEvent.RESIZE)
    private function onResize(e)
    {
        var unit:Float = this.height / 11;

        var newLabelStyle = label.customStyle.clone();
        newLabelStyle.fontSize = 9.6 * unit;
        label.customStyle = newLabelStyle;

        var newCardStyle = card.customStyle.clone();
        newCardStyle.paddingTop = unit;
        newCardStyle.paddingBottom = unit;
        newCardStyle.paddingLeft = 4 * unit;
        newCardStyle.paddingRight = 4 * unit;
        card.customStyle = newCardStyle;
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

        var newCardStyle = card.customStyle.clone();
        newCardStyle.backgroundColor = backgroundColor;
        card.customStyle = newCardStyle;
    }

    private function updateTimeLeft() 
    {
        if (running)
            secondsLeft = Math.max(secondsLeftAtReliableTimestamp - reliableTimestamp.getIntervalSecsToNow(), 0);
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

    private function correctTime(secs:Float, calculatedAt:UnixTimestamp) 
    {
        secondsLeftAtReliableTimestamp = secs;
        reliableTimestamp = calculatedAt;
        updateTimeLeft();
    }

    public function new(ownerColor:PieceColor)
    {
        super();
        this.ownerColor = ownerColor;
    }
}