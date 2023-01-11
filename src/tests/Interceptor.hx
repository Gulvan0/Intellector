package tests;

import haxe.ui.events.KeyboardEvent;
import haxe.ui.core.Screen;

class Interceptor
{
    private static var handlers:Map<Int, Void->Void> = [];

    private static function processBtn(e:KeyboardEvent) 
    {
        var handler:Null<Void->Void> = handlers.get(e.keyCode);

        if (handler != null)
        {
            trace("Executing handler for keyCode: " + e.keyCode);
            handler();
        }
    }

    public static function setHandler(keyCode:Int, handler:Void->Void) 
    {
        handlers.set(keyCode, handler);
    }

    public static function removeHandler(keyCode:Int) 
    {
        handlers.remove(keyCode);
    }

    public static function init()
    {
        Screen.instance.registerEvent(KeyboardEvent.KEY_DOWN, processBtn);
    }
}