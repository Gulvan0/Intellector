package client.watch;

import client.datatypes.watch.WatchedPlayer;
import client.storage.WatchedPlayerStorage;

/** The player the user watches, if any, the same in every tab **/
class WatchKeeper
{
    public static var watched(default, null):Null<WatchedPlayer> = null;

    private static var changeListeners:Array<Null<WatchedPlayer>->Void> = [];

    /** Restores the stored player, telling every listener, `initialChangeListeners` first **/
    public static function init(initialChangeListeners:Array<Null<WatchedPlayer>->Void>):Void
    {
        changeListeners = initialChangeListeners.concat(changeListeners);
        WatchedPlayerStorage.addExternalChangeHandler(apply);
        apply(WatchedPlayerStorage.read());
    }

    /** Replaces whoever is watched **/
    public static function watch(player:WatchedPlayer):Void
    {
        WatchedPlayerStorage.save(player);
        apply(player);
    }

    public static function stop():Void
    {
        WatchedPlayerStorage.save(null);
        apply(null);
    }

    public static function isWatching(login:String):Bool
    {
        return watched != null && watched.login == login;
    }

    public static function addChangeListener(callback:Null<WatchedPlayer>->Void):Void
    {
        changeListeners.push(callback);
    }

    public static function removeChangeListener(callback:Null<WatchedPlayer>->Void):Void
    {
        changeListeners.remove(callback);
    }

    private static function apply(player:Null<WatchedPlayer>):Void
    {
        if (player?.login == watched?.login && player?.nickname == watched?.nickname)
            return;

        watched = player;
        for (listener in changeListeners.copy())
            listener(watched);
    }
}
