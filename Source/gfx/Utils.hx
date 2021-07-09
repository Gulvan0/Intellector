package gfx;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

class Utils 
{
    public static function add(container:DisplayObjectContainer, obj:DisplayObject, ?x:Float, ?y:Float, ?invisible:Bool = false) 
    {
        if (x != null)
            obj.x = x;
        if (y != null)
            obj.y = y;
        obj.visible = !invisible;
        container.addChild(obj);
    }    
}