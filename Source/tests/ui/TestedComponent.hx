package tests.ui;

import tests.ui.utils.components.AdjustableContentBox;
import haxe.ui.components.Spacer;
import haxe.ui.components.Label;
import haxe.ui.events.UIEvent;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Slider;
import gfx.components.Shapes;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import gfx.components.BoardWrapper;
import gfx.components.SpriteWrapper;
import haxe.ui.containers.Box;
import gameboard.Board;
import gfx.components.Dialogs;
import haxe.ui.core.Component;
import struct.Situation;
import openfl.display.Sprite;

enum ComponentGraphics
{
    Board(board:Board);
    Sprite(sprite:Sprite);
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
        return Situation.starting();
    }

    public function imitateEvent(encodedEvent:String)
    {
        throw "Not overriden";
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
        Dialogs.info(message, 'output');
    }

    public function update()
    {
        removeAllComponents();
        rebuildComponent();
        var compGfx:ComponentGraphics = getComponent();
        switch compGfx 
        {
            case Board(board):
                var boardWrapper:BoardWrapper = new BoardWrapper(board);
                boardWrapper.percentWidth = 90;
                boardWrapper.horizontalAlign = 'center';
                boardWrapper.verticalAlign = 'center';
                addComponent(boardWrapper);
            case Sprite(sprite):
                var componentWrapper:SpriteWrapper = new SpriteWrapper(sprite, false);
                componentWrapper.horizontalAlign = 'center';
                componentWrapper.verticalAlign = 'center';
                addComponent(componentWrapper);
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