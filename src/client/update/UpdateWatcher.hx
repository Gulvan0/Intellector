package client.update;

import client.build.BuildInfo;
import haxe.Timer;
import haxefolio.HaxeFolioApp;
import haxefolio.browser.ActivityTracker;
import js.Browser;
import js.html.Response;
import morestd.DateTime;

/**
    Notices that the server hosts a newer build of this API version and reloads into it without
    asking: at once while the tab is hidden, otherwise on the next in-app navigation or after a
    minute without input. Nothing happens while `isProtected` holds.
**/
class UpdateWatcher
{
    private static inline final CHECK_INTERVAL_MS:Int = 5 * 60 * 1000;
    private static inline final PENDING_POLL_INTERVAL_MS:Int = 5 * 1000;
    private static inline final IDLE_RELOAD_SECS:Int = 60;

    private static var isProtected:Void->Bool;
    private static var pendingSinceUnixSecs:Null<Int> = null;
    private static var pendingPollTimer:Null<Timer> = null;

    /** `isProtected` tells whether a reload now would lose the user's work **/
    public static function init(isProtected:Void->Bool):Void
    {
        if (!BuildInfo.IS_DEPLOYABLE)
            return;

        UpdateWatcher.isProtected = isProtected;
        new Timer(CHECK_INTERVAL_MS).run = check;
        Browser.document.addEventListener("visibilitychange", onVisibilityChanged);
        HaxeFolioApp.reloadOnNavigation = () -> pendingSinceUnixSecs != null && !isProtected();
    }

    /** Looks for a newer build; does nothing for a build that isn't deployed **/
    public static function check():Void
    {
        if (!BuildInfo.IS_DEPLOYABLE || pendingSinceUnixSecs != null)
            return;

        Browser.window.fetch("bin/version.json", {cache: NO_CACHE})
            .then((response:Response) -> response.json())
            .then((version:Dynamic) -> {
                if (version.build != BuildInfo.BUILD_ID)
                    markPending();
            })
            .catchError(_ -> {});
    }

    private static function markPending():Void
    {
        pendingSinceUnixSecs = DateTime.nowUnixSecs();
        pendingPollTimer = new Timer(PENDING_POLL_INTERVAL_MS);
        pendingPollTimer.run = reloadIfDue;
        reloadIfDue();
    }

    private static function onVisibilityChanged():Void
    {
        if (Browser.document.hidden)
            reloadIfDue();
        else
            check();
    }

    private static function reloadIfDue():Void
    {
        if (pendingSinceUnixSecs == null || isProtected())
            return;

        var lastInputUnixSecs:Int = Std.int(Math.max(ActivityTracker.getLastActivityTs(), pendingSinceUnixSecs));
        if (Browser.document.hidden || DateTime.nowUnixSecs() - lastInputUnixSecs >= IDLE_RELOAD_SECS)
            Browser.location.reload();
    }
}
