package client.ui.games.flow;

import haxe.ui.core.Component;
import js.Browser;

/** Whether the running flow is in a sheet (Narrow) or popovers (Wide), for the steps to size themselves **/
class FlowLayout
{
    public static var narrow:Bool = false;

    /** As wide as the sheet, or `wideWidth` in a popover **/
    public static function size(component:Component, wideWidth:Float):Void
    {
        if (narrow)
            component.percentWidth = 100;
        else
            component.width = wideWidth;
    }

    /** A scrolling list's height cap in a popover; none in a sheet, which scrolls itself **/
    public static function listHeight(wideMax:Float):Null<Float>
    {
        return narrow ? null : Math.min(wideMax, Browser.window.innerHeight * 0.6);
    }

    /** The width a list takes: the sheet's, or `wideWidth` **/
    public static function listWidth(wideWidth:Float):Null<Float>
    {
        return narrow ? null : wideWidth;
    }
}
