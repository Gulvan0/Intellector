package tests;

import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import openfl.Lib;

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
        Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, processBtn);
    }
}