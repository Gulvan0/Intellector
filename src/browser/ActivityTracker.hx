package browser;

import lib.std.DateTime;
import js.html.Event;
import js.Browser;

class ActivityTracker
{
    private static var lastActivityTs:Int;

    public static function init()
    {
        for (eventKind in ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'])
            Browser.document.addEventListener(eventKind, updateTs);
    }

    public static function getLastActivityTs():Int
    {
        return lastActivityTs;
    }

    private static function updateTs(event:Event)
    {
        lastActivityTs = DateTime.nowUnixSecs();
    }
}
