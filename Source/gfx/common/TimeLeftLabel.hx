package gfx.common;

import haxe.Timer;
import openfl.Assets;
import haxe.ui.styles.Style;
import utils.TimeControl;
import haxe.ui.components.Label;

class TimeLeftLabel extends Label
{
    private static var defaultStyle:Style = {fontSize: 40};
    private static var hurryStyle:Style = {fontSize: 40, color: 0xCC0000};

    public var secondsLeft(default, null):Float;
    public var notifyOnOneMinuteLeft:Bool;
    public var alertsEnabled:Bool;

    private var timer:Timer;
    private var timerPrecise:Bool;
    private var lastUpdate:Float;

    private function timerRun() 
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
            text = TimeControl.secsToString(0);
            Networker.reqTimeoutCheck();
            return;
        }

        text = TimeControl.secsToString(secondsLeft);

        if (alertsEnabled)
        {
            if (secondsLeft < 60)
            {
                customStyle = hurryStyle;

                if (notifyOnOneMinuteLeft)
                {
                    Assets.getSound("sounds/lowtime.mp3").play();
                    notifyOnOneMinuteLeft = false;
                }
            }
            else
                customStyle = defaultStyle;
        }

        if (timer != null && (secondsLeft <= 10 && !timerPrecise || secondsLeft > 10 && timerPrecise))
        {
            timer.stop();
            timerPrecise = secondsLeft <= 10;
            timer = new Timer(timerPrecise? 10 : 1000);
            timer.run = timerRun;
        }
    }

    public function launchTimer()
    {
        if (timer != null)
            timer.stop();

        timerPrecise = secondsLeft <= 10;

        lastUpdate = Date.now().getTime();
        timer = new Timer(timerPrecise? 10 : 1000);
        timer.run = timerRun;
    }

    public function stopTimer() 
    {
        if (timer != null)
            timer.stop();
        timer = null;
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
        onTimeUpdated();
    }

    public function new(initialSeconds:Float, alertsEnabled:Bool, ?notifyOnOneMinuteLeft:Bool = true) 
    {
        super();

        this.notifyOnOneMinuteLeft = notifyOnOneMinuteLeft;
        this.alertsEnabled = alertsEnabled;
        this.timerPrecise = initialSeconds <= 10;

        text = TimeControl.secsToString(initialSeconds);
        customStyle = defaultStyle;
    }
}