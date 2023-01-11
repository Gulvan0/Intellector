package gfx.basic_components;

import haxe.ui.containers.Box;
import haxe.ui.events.UIEvent;

class Square extends Box
{
    private var widthBased:Bool = true;

    @:bind(this, UIEvent.RESIZE)
    private function onResizeEvent(e)
    {
        if (widthBased)
            height = width;
        else
            width = height;
    }

    private override function set_width(value:Null<Float>):Null<Float> 
    {
        widthBased = true;
        return super.set_width(value);
    }
    
    private override function set_percentWidth(value:Null<Float>):Null<Float> 
    {
        widthBased = true;
        return super.set_percentWidth(value);
    }

    private override function set_height(value:Null<Float>):Null<Float> 
    {
        widthBased = false;
        return super.set_height(value);
    }
    
    private override function set_percentHeight(value:Null<Float>):Null<Float> 
    {
        widthBased = false;
        return super.set_percentHeight(value);
    }
}