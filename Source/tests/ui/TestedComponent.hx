package tests.ui;

import gfx.components.Dialogs;
import haxe.ui.core.Component;
import struct.Situation;
import openfl.display.Sprite;

enum ComponentGraphics
{
    Sprite(sprite:Sprite);
    Component(component:Component);
}

class TestedComponent extends Component
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
        //TODO: Customize layout
    }
}