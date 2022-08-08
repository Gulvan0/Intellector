package gfx.game;

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
class Clock extends Card
{
    private var playSoundOnOneMinuteLeft:Bool;
    private var alertsEnabled:Bool;

    private var secondsLeftAtReliableTimestamp:Float;
    private var reliableTimestamp:Float;
    private var running:Bool = false;

    private var active:Bool;
    private var playerMove:Bool;
    private var moveNum:Int;

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

    private function refreshColoring()
    {
        var backgroundColor:Int = -1;
        var textColor:Int = -1;
        var lowTime:Bool = alertsEnabled && secondsLeft < 60;

        if (active && playerMove && lowTime)
        {
            backgroundColor = 0xffbbbb;
            textColor = 0xaa0000;
        }
        else if (active && playerMove && !lowTime)
        {
            backgroundColor = 0xd5e5d3;
            textColor = 0x000000;
        }
        else if (active && !playerMove && lowTime)
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
        var secondsLeft:Float;

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

    public function deactivate()
    {
        active = false;
        if (running)
            pauseTimer();
        refreshColoring();

        for (copycat in copycats)
            copycat.deactivate();
    }

    public function correctTime(secsLeft:Float, validAt:Float) 
    {
        secondsLeftAtReliableTimestamp = secsLeft;
        reliableTimestamp = validAt;
        updateTimeLeft();

        for (copycat in copycats)
            copycat.correctTime(secsLeft, actualTimestamp);
    }

    public function addTime(secs:Float) 
    {
        correctTime(secondsLeftAtReliableTimestamp + secs, reliableTimestamp);
    }

    public function onMoveMade(secsLeftAtMoment:Float, timestamp:Float)
    {
        correctTime(secsLeftAtMoment, timestamp);
        playerMove = !playerMove;
        moveNum++;
        refreshColoring();

        if (moveNum >= 2)
            if (playerMove)
                launchTimer();
            else
                pauseTimer();
        
        for (copycat in copycats)
            copycat.onMoveMade(secsLeftAtMoment, timestamp);
    }

    public function onReverted(ownerToMove:Bool, secsLeftAtMoment:Float, timestamp:Float)
    {
        if (playerMove == ownerToMove)
            return;

        correctTime(secsLeftAtMoment, timestamp);
        playerMove = ownerToMove;
        refreshColoring();

        if (moveNum >= 2)
            if (playerMove)
                launchTimer();
            else
                pauseTimer();
        
        for (copycat in copycats)
            copycat.onReverted(ownerToMove, secsLeftAtMoment, timestamp);
    }

    public function init(constructor:LiveGameConstructor, ownerColor:PieceColor)
    {
        switch constructor 
        {
            case New(whiteLogin, blackLogin, timeControl, startingSituation):
                this.playSoundOnOneMinuteLeft = timeControl.startSecs >= 90;
                this.alertsEnabled = LoginManager.isPlayer(ownerColor == White? whiteLogin : blackLogin);
                this.secondsLeft = timeControl.startSecs;
                this.active = true;
                this.playerMove = startingSituation.turnColor == ownerColor;
                this.moveNum = 0;

                label.text = TimeControl.secsToString(initialSeconds);
            case Ongoing(parsedData, whiteSeconds, blackSeconds, timeValidAtTimestamp):
                this.playSoundOnOneMinuteLeft = parsedData.timeControl.startSecs >= 90;
                this.alertsEnabled = parsedData.getPlayerColor() == ownerColor;
                this.secondsLeft = timeControl.startSecs;
                this.active = true;
                this.playerMove = parsedData.currentSituation.turnColor == ownerColor;
                this.moveNum = parsedData.moveCount;

                correctTime(ownerColor == White? whiteSeconds : blackSeconds, timeValidAtTimestamp);
                if (playerMove && moveNum >= 2)
                    launchTimer();  //TODO: Won't launch the timer if took back until move 1, then reconnected

            case Past(parsedData):
                this.active = false;
                if (parsedData.msLeftWhenEnded != null)
                    label.text = TimeControl.secsToString(parsedData.msLeftWhenEnded * 1000);
                else
                    hidden = true;
        }
    }
    
    public function new()
    {
        super();
    }
}