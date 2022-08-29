package tests.ui.utils.components;

import gfx.Dialogs;
import haxe.Timer;
import js.Browser;
import haxe.ui.events.UIEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/testenv/sequencewidget.xml"))
class SequenceWidget extends VBox
{
    private var currentStep:Int;
    private var totalSteps:Int;

    private var playTimer:Timer;

    private var stepCallback:Int->Void;
    private var removeCallback:Void->Void;
    private var renameCallback:String->Void;

    private function updateStepLabel()
    {
        macroStepLabel.text = '$currentStep/$totalSteps';
    }

    private function updateSliderPosLabel()
    {
        var msInt:Int = Math.round(intervalSlider.pos);
        if (intervalSlider.pos < 1000)
            sliderPosLabel.text = "Interval: 0." + msInt + "s";
        else
        {
            var sStr = Std.string(msInt);
            sliderPosLabel.text = "Interval: " + sStr.substring(0, sStr.length - 3) + "." + sStr.substring(sStr.length - 3) + "s";
        }
    }

    private function step()
    {
        stepCallback(currentStep);
        currentStep = (currentStep + 1) % totalSteps;
        updateStepLabel();
    }

    private function playTimerCallback()
    {
        step();
        if (currentStep == 0)
        {
            playTimer.stop();
            playTimer = null;
            removeBtn.disabled = false;
            editBtn.disabled = false;
            playBtn.disabled = false;
            stepBtn.disabled = false;
        }
    }

    @:bind(stepBtn, MouseEvent.CLICK)
    private function onStep(e)
    {
        step();
    }

    @:bind(playBtn, MouseEvent.CLICK)
    private function onPlay(e)
    {
        removeBtn.disabled = true;
        editBtn.disabled = true;
        playBtn.disabled = true;
        stepBtn.disabled = true;
        playTimer = new Timer(Math.round(intervalSlider.pos));
        playTimer.run = playTimerCallback;
    }

    @:bind(removeBtn, MouseEvent.CLICK)
    private function onRemove(e)
    {
        removeCallback();
    }

    @:bind(editBtn, MouseEvent.CLICK)
    private function onRename(e)
    {
        var response:String = Browser.window.prompt("Enter the new macro name:");
        if (response != null && response != "")
        {
            if (DataKeeper.getAllMacroNames().contains(response))
                Dialogs.alertRaw("Failed to add macro: a macro with this name already exists", "TestEnv Warning");
            else
            {
                macroNameLabel.text = response;
                renameCallback(response);
            }
        }
    }

    @:bind(intervalSlider, UIEvent.CHANGE)
    private function onSpeedChanged(e)
    {
        updateSliderPosLabel();
    }

    public function makeEditable(removeCallback:Void->Void, renameCallback:String->Void)
    {
        this.removeCallback = removeCallback;
        this.renameCallback = renameCallback;
        removeBtn.hidden = false;
        editBtn.hidden = false;
    }

    public function new(sequenceName:String, totalSteps:Int, stepCallback:Int->Void) 
    {
        super();
        this.currentStep = 0;
        this.totalSteps = totalSteps;
        this.stepCallback = stepCallback;

        macroNameLabel.text = sequenceName;
        macroNameLabel.tooltip = sequenceName;
        updateStepLabel();
        updateSliderPosLabel();
    }    
}