package client.ui.common;

import haxe.ui.Toolkit;
import haxe.ui.core.Component;
import morestd.Detachable;

/** Reports a component's own rendered width, for layouts that follow their container rather than the viewport **/
class WidthObserver
{
    /** Calls `onWidth` with `component`'s width whenever it changes, until the handle is detached **/
    public static function observe(component:Component, onWidth:Float->Void):Detachable
    {
        var lastWidth:Float = -1;
        var observer:Dynamic = js.Syntax.code("new ResizeObserver({0})", (_:Array<Dynamic>) -> {
            var width:Float = component.element.offsetWidth / Toolkit.scaleX;
            if (width > 0 && width != lastWidth)
            {
                lastWidth = width;
                onWidth(width);
            }
        });
        observer.observe(component.element);
        return new Detachable(() -> observer.disconnect(), false);
    }
}
