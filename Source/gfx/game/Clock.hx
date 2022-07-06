package gfx.game;

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
    public var playSoundOnOneMinuteLeft:Bool;
    public var alertsEnabled:Bool;

    private var lastUpdate:Float;
    private var playerMove:Bool;

    private var copycats:Array<Clock> = [];

    public function addCopycat(copycat:Clock) 
    {
        copycats.push(copycat);
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

    public function setPlayerMove(v:Bool) 
    {
        var changed:Bool = playerMove != v;
        playerMove = v;
        if (changed)
            refreshColoring();
        for (copycat in copycats)
            copycat.setPlayerMove(v);
    }

    private function refreshColoring()
    {
        var backgroundColor:Int = -1;
        var textColor:Int = -1;
        var lowTime:Bool = alertsEnabled && secondsLeft < 60;

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
        else
            throw "Impossible situation at Clock::refreshColoring()";

        var newLabelStyle = label.customStyle.clone();
        newLabelStyle.color = textColor;
        label.customStyle = newLabelStyle;

        var newCardStyle = this.customStyle.clone();
        newCardStyle.backgroundColor = backgroundColor;
        this.customStyle = newCardStyle;
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
            pauseTimer();
            secondsLeft = 0;
            label.text = TimeControl.secsToString(0);
            Networker.emitEvent(RequestTimeoutCheck);
            return;
        }

        label.text = TimeControl.secsToString(secondsLeft);

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

    public function launchTimer()
    {
        lastUpdate = Date.now().getTime();
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
        refreshColoring();
        for (copycat in copycats)
            copycat.launchTimer();
    }

    public function stopClockCompletely()
    {
        pauseTimer();
        setPlayerMove(false);
        for (copycat in copycats)
            copycat.stopClockCompletely();
    }

    public function pauseTimer() 
    {
        removeEventListener(Event.ENTER_FRAME, onEnterFrame);

        refreshColoring();

        for (copycat in copycats)
            copycat.pauseTimer();
    }

    public function correctTime(secsLeft:Float, actualTimestamp:Float) 
    {
        secondsLeft = secsLeft;
        lastUpdate = actualTimestamp;
        onTimeUpdated();

        for (copycat in copycats)
            copycat.correctTime(secsLeft, actualTimestamp);
    }

    public function addTime(secs:Float) 
    {
        secondsLeft += secs;
        label.text = TimeControl.secsToString(secondsLeft);
        refreshColoring();

        for (copycat in copycats)
            copycat.addTime(secs);
    }

    public function init(initialSeconds:Float, alertsEnabled:Bool, playSoundOnOneMinuteLeft:Bool, isOwnerToMove:Bool) 
    {
        this.playSoundOnOneMinuteLeft = playSoundOnOneMinuteLeft;
        this.alertsEnabled = alertsEnabled;
        this.secondsLeft = initialSeconds;

        setPlayerMove(isOwnerToMove);
        label.text = TimeControl.secsToString(initialSeconds);
    }
    
    public function new()
    {
        super();
    }
}