package client.storage;

import client.datatypes.watch.WatchedPlayer;
import haxefolio.HaxeFolioApp;

/** The watched player in localStorage, shared by the browser's tabs **/
class WatchedPlayerStorage
{
    public static function read():Null<WatchedPlayer>
    {
        return deserialize(HaxeFolioApp.valueStorage.read(LocalStorageKey.WATCHED_PLAYER));
    }

    /** Null: watching no one **/
    public static function save(player:Null<WatchedPlayer>):Void
    {
        if (player != null)
            HaxeFolioApp.valueStorage.write(LocalStorageKey.WATCHED_PLAYER, '${player.login};${player.nickname}');
        else
            HaxeFolioApp.valueStorage.remove(LocalStorageKey.WATCHED_PLAYER);
    }

    /** `handler` gets the player another tab stores **/
    public static function addExternalChangeHandler(handler:Null<WatchedPlayer>->Void):Void
    {
        HaxeFolioApp.valueStorage.addExternalChangeHandler(LocalStorageKey.WATCHED_PLAYER, serialized -> handler(deserialize(serialized)));
    }

    // `<login>;<nickname>`; a login has no `;`
    private static function deserialize(serialized:Null<String>):Null<WatchedPlayer>
    {
        if (serialized == null)
            return null;

        var separator:Int = serialized.indexOf(";");
        if (separator <= 0)
            return null;

        return new WatchedPlayer(serialized.substring(0, separator), serialized.substr(separator + 1));
    }
}
