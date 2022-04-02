package gfx.common;

import openfl.events.Event;
import haxe.ui.containers.Box;
import haxe.Timer;
import openfl.Assets;
import haxe.ui.styles.Style;
import haxe.ui.containers.Card;
import utils.TimeControl;
import haxe.ui.components.Label;
import haxe.ui.macros.ComponentMacros;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/clock.xml"))
class Clock extends Card
{
    public var secondsLeft(default, null):Float;
    public var notifyOnOneMinuteLeft:Bool;
    public var alertsEnabled:Bool;

    private var timerRunning:Bool = false;
    private var lastUpdate:Float;

    private function applyColoring(playerMove:Bool, lowTime:Bool)
    {
        var backgroundColor:Int = -1;
        var textColor:Int = -1;

        if (playerMove && lowTime)
        {
            backgroundColor = 0xffbbbb;
            textColor = 0xaa0000;
        }
        else if (playerMove && !lowTime)
        {
            backgroundColor = 0xd5e5d3;
            textColor = 0x000000;
        }
        else if (!playerMove && lowTime)
        {
            backgroundColor = 0xffdddd;
            textColor = 0x666666;
        }
        else if (!playerMove && !lowTime)
        {
            backgroundColor = 0xffffff;
            textColor = 0x666666;
        }

        label.applyStyle({color: textColor});
        this.applyStyle({backgroundColor: backgroundColor});
    }

    private function onEnterFrame(e)
    {
        var timestamp:Float = Date.now().getTime();
        secondsLeft -= (timestamp - lastUpdate) / 1000;
        onTimeUpdated();
        lastUpdate = timestamp;
    }

    private function onTimeUpdated() 
    {
        if (secondsLeft <= 0)
        {
            stopTimer();
            secondsLeft = 0;
            label.text = TimeControl.secsToString(0);
            Networker.emitEvent(RequestTimeoutCheck);
            return;
        }

        text = TimeControl.secsToString(secondsLeft);

        if (alertsEnabled)
        {
            var lowTime:Bool = secondsLeft < 60;
            applyColoring(timerRunning, lowTime);

            if (lowTime && notifyOnOneMinuteLeft)
            {
                Assets.getSound("sounds/lowtime.mp3").play();
                notifyOnOneMinuteLeft = false;
            }
        }
    }

    public function launchTimer()
    {
        lastUpdate = Date.now().getTime();
        timerRunning = true;
        addEventListener(Event.ENTER_FRAME, onEnterFrame);

        var lowTime:Bool = secondsLeft < 60;
        applyColoring(timerRunning, lowTime);
    }

    public function stopTimer() 
    {
        timerRunning = false;
        removeEventListener(Event.ENTER_FRAME, onEnterFrame);

        var lowTime:Bool = secondsLeft < 60;
        applyColoring(timerRunning, lowTime);
    }

    public function correctTime(secsLeft:Float, actualTimestamp:Float) 
    {
        secondsLeft = secsLeft;
        lastUpdate = actualTimestamp;
        onTimeUpdated();
    }

    public function addTime(secs:Float) 
    {
        secondsLeft += secs;
        text = TimeControl.secsToString(secondsLeft);
        if (secondsLeft >= 60)
            applyColoring(timerRunning, false);
    }

    public function init(initialSeconds:Float, alertsEnabled:Bool, notifyOnOneMinuteLeft:Bool) 
    {
        this.notifyOnOneMinuteLeft = notifyOnOneMinuteLeft;
        this.alertsEnabled = alertsEnabled;

        label.text = TimeControl.secsToString(initialSeconds);
    }
    
    public function new()
    {
        super();
    }
}