package;

import Preferences.PreferenceName;

enum GlobalEvent
{
    LoggedIn;
    LoggedOut;
    PreferenceUpdated(name:PreferenceName);
}

interface IGlobalEventObserver 
{
    public function handleGlobalEvent(event:GlobalEvent):Void;
}

class GlobalBroadcaster
{
    private static var observers:Array<IGlobalEventObserver> = [];

    public static function broadcast(event:GlobalEvent) 
    {
        for (obs in observers)
            obs.handleGlobalEvent(event);
    }

    public static function addObserver(obs:IGlobalEventObserver) 
    {
        observers.push(obs);
    }

    public static function removeObserver(obs:IGlobalEventObserver) 
    {
        observers.remove(obs);
    }
}