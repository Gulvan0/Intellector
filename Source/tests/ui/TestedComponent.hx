package tests.ui;

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

    public function _imitateEvent(encodedEvent:String)
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
        Dialogs.alert(message, 'output');
    }
    //TODO: (in UITest.hx on button pressed) emit signals for board view; log to history

    public function new() 
    {
        super();
        //TODO: Resizability
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
                var widthSliderName:Label = new Label();
                widthSliderName.height = 30;
                widthSliderName.text = "Width: ";

                widthSlider = new HorizontalSlider();
                widthSlider.height = 30;
                widthSlider.min = minWidth;
                widthSlider.max = maxWidth;
                widthSlider.pos = (minWidth+maxWidth)/2;
                widthSlider.disabled = minWidth == maxWidth || minWidth <= 0 || maxWidth <= 0;
                widthSlider.onChange = e -> {
                    adjustableContentContainer.width = widthSlider.pos;
                    widthLabel.text = '' + Math.round(widthSlider.pos);
                }

                widthLabel = new Label();
                widthLabel.width = 50;
                widthLabel.height = 30;
                widthLabel.text = (minWidth <= 0 || maxWidth <= 0)? "" : '' + Math.round(widthSlider.pos);

                var spacer:Spacer = new Spacer();
                spacer.percentWidth = 33;

                var heightSliderName:Label = new Label();
                heightSliderName.height = 30;
                heightSliderName.text = "Height: ";
                
                heightSlider = new HorizontalSlider();
                heightSlider.height = 30;
                heightSlider.min = minHeight;
                heightSlider.max = maxHeight;
                heightSlider.pos = (minHeight+maxHeight)/2;
                heightSlider.disabled = minHeight == maxHeight || minHeight <= 0 || maxHeight <= 0;
                heightSlider.onChange = e -> {
                    adjustableContentContainer.height = heightSlider.pos;
                    heightLabel.text = '' + Math.round(heightSlider.pos);
                }

                heightLabel = new Label();
                heightLabel.width = 50;
                heightLabel.height = 30;
                heightLabel.text = (minHeight <= 0 || maxHeight <= 0)? "" : '' + Math.round(heightSlider.pos);

                var adjustersBox:HBox = new HBox();
                adjustersBox.percentWidth = 100;
                adjustersBox.height = 30;
                adjustersBox.addComponent(widthSliderName);
                adjustersBox.addComponent(widthSlider);
                adjustersBox.addComponent(widthLabel);
                adjustersBox.addComponent(spacer);
                adjustersBox.addComponent(heightSliderName);
                adjustersBox.addComponent(heightSlider);
                adjustersBox.addComponent(heightLabel);
                
                adjustableContentContainer = new Box();
                if (minWidth > 0 && maxWidth > 0)
                    adjustableContentContainer.width = widthSlider.pos;
                if (minHeight > 0 && maxHeight > 0)
                    adjustableContentContainer.height = heightSlider.pos;
                adjustableContentContainer.horizontalAlign = 'center';
                adjustableContentContainer.verticalAlign = 'center';
                adjustableContentContainer.addComponent(component);

                var mainBox:Box = new Box();
                mainBox.percentWidth = 100;
                mainBox.percentHeight = 100;
                mainBox.addComponent(adjustableContentContainer);

                var vbox:VBox = new VBox();
                vbox.percentWidth = 100;
                vbox.percentHeight = 100;
                vbox.addComponent(adjustersBox);
                vbox.addComponent(mainBox);

                addComponent(vbox);
        }
    }
}