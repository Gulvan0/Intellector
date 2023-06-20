package gfx.scene;

import gfx.scene.systems.NotificationSystem;
import gfx.scene.systems.BrowserEnvironmentSystem;
import haxe.ui.core.Component;
import net.shared.utils.UnixTimestamp;
import haxe.ui.events.UIEvent;
import haxe.Timer;
import net.Networker;
import net.shared.message.ServerEvent;
import haxe.ui.core.Screen as HaxeUIScreen;

using StringTools;

class SceneManager
{
    private static var scene:Scene;
    private static var browserEnvironmentSystem:BrowserEnvironmentSystem;
    private static var notificationSystem:NotificationSystem;

    private static var lastResizeTimestamp:Float;
    private static var cachedWidth:Float;
    private static var cachedHeight:Float;
    private static var resizeHandlers:Array<Void->Void> = [];
    private static var resizeTimeout:Null<Timer>;

    public static function getScene():IPublicScene
    {
        return scene;
    }

    public static function addResizeHandler(handler:Void->Void)
    {
        resizeHandlers.push(handler);
    }

    public static function removeResizeHandler(handler:Void->Void)
    {
        resizeHandlers.remove(handler);
    }

    private static function onResized(?e)
    {
        var timestamp:Float = UnixTimestamp.now().toUnixMilliseconds();
        var msSinceLastResize:Float = timestamp - lastResizeTimestamp;

        if (msSinceLastResize > 100 && (cachedWidth != HaxeUIScreen.instance.actualWidth || cachedHeight != HaxeUIScreen.instance.actualHeight))
        {
            lastResizeTimestamp = timestamp;
            cachedWidth = HaxeUIScreen.instance.actualWidth;
            cachedHeight = HaxeUIScreen.instance.actualHeight;

            scene.resize();

            for (handler in resizeHandlers)
                handler();
        }
        else if (resizeTimeout == null)
            resizeTimeout = Timer.delay(onDelayedResizeTimerFired, Math.ceil(100 - msSinceLastResize));
    }

    private static function onDelayedResizeTimerFired()
    {
        resizeTimeout = null;
        onResized();
    }

    public static function launch():Scene
    {
        scene = new Scene();
        GlobalBroadcaster.addObserver(scene);
        Networker.addObserver(scene);

        browserEnvironmentSystem = new BrowserEnvironmentSystem();
        GlobalBroadcaster.addObserver(browserEnvironmentSystem);

        notificationSystem = new NotificationSystem();
        Networker.addObserver(notificationSystem);

        lastResizeTimestamp = UnixTimestamp.now().toUnixMilliseconds();
        cachedWidth = HaxeUIScreen.instance.actualWidth;
        cachedHeight = HaxeUIScreen.instance.actualHeight;

        scene.resize();
        HaxeUIScreen.instance.registerEvent(UIEvent.RESIZE, onResized);

        return scene;
    }
}