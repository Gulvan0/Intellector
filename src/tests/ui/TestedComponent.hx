package tests.ui;

import tests.ui.utils.components.AdjustableContentBox;
import haxe.ui.components.Spacer;
import haxe.ui.components.Label;
import haxe.ui.events.UIEvent;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Slider;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.containers.Box;
import gameboard.Board;
import gfx.Dialogs;
import haxe.ui.core.Component;
import net.shared.board.Situation;

enum ComponentGraphics
{
    AdjustableContent(component:Component, minWidth:Float, maxWidth:Float, minHeight:Float, maxHeight:Float);
    Component(component:Component);
}

class TestedComponent extends Box
{
    private var adjustableContentContainer:Box;
    private var widthSlider:Slider;
    private var heightSlider:Slider;
    private var widthLabel:Label;
    private var heightLabel:Label;

    //To be overriden in the subclasses as well
    public function _provide_situation():Situation
    {
        return Situation.defaultStarting();
    }

    public function imitateEvent(encodedEvent:String)
    {
        throw "Not overriden";
    }

    //To be overriden in the subclasses as well
    public function onDialogShown()
    {
        //* Do nothing
    }

    //To be overriden in the subclasses as well
    public function onDialogHidden()
    {
        //* Do nothing
    }

    private function getComponent():ComponentGraphics
    {
        throw "Not overriden";
    }

    private function rebuildComponent():Void
    {
        throw "Not overriden";
    }

    private function output(message:String) 
    {
        Dialogs.alertRaw(message, 'output');
    }

    public function update()
    {
        removeAllComponents();
        rebuildComponent();
        var compGfx:ComponentGraphics = getComponent();
        switch compGfx 
        {
            case Component(component):
                component.horizontalAlign = 'center';
                component.verticalAlign = 'center';
                addComponent(component);
            case AdjustableContent(component, minWidth, maxWidth, minHeight, maxHeight):
                addComponent(new AdjustableContentBox(component, minWidth, maxWidth, minHeight, maxHeight));
        }
    }

    public function new() 
    {
        super();

        percentWidth = 100;
        percentHeight = 100;

        update();
    }
}