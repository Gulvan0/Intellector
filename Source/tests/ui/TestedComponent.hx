package tests.ui;

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
    Component(component:Component);
}

class TestedComponent extends Box
{
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
        }
    }
}