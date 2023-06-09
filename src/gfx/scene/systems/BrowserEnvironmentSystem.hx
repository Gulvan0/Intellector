package gfx.scene.systems;

import js.Browser;
import GlobalBroadcaster.GlobalEvent;
import GlobalBroadcaster.IGlobalEventObserver;

class BrowserEnvironmentSystem implements IGlobalEventObserver
{
    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case LockedInGame:
                Browser.window.onpopstate = SceneManager.getScene().refreshTitleAndUrl;
            case NotLockedInGame:
                Browser.window.onpopstate = ScreenNavigator.navigate;
            default:
        }
    }

    public function new()
    {

    }
}