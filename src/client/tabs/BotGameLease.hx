package client.tabs;

import client.storage.LocalStorageKey;
import haxefolio.HaxeFolioApp;

/**
    Which of the browser's tabs computes the bot's moves in a game: the one holding the game's lease. The holder renews
    it every `RENEWAL_INTERVAL_MS`; a lease not renewed for `EXPIRY_MS` is free to take over.
**/
class BotGameLease
{
    public static inline final RENEWAL_INTERVAL_MS:Int = 2000;
    public static inline final EXPIRY_MS:Int = 6000;

    private static final TAB_ID:String = Std.string(Std.random(0x7FFFFFFF)) + "-" + Std.string(Date.now().getTime());

    /** Takes the lease of game `gameId` unless another tab holds it; returns whether this tab holds it now **/
    public static function tryAcquire(gameId:Int):Bool
    {
        var holder:Null<String> = holderOf(gameId);
        if (holder != null && holder != TAB_ID)
            return false;

        renew(gameId);
        return holderOf(gameId) == TAB_ID;
    }

    public static function renew(gameId:Int):Void
    {
        HaxeFolioApp.valueStorage.write(key(gameId), TAB_ID + ";" + Std.string(Date.now().getTime()));
    }

    /** Frees the lease of game `gameId` if this tab holds it **/
    public static function release(gameId:Int):Void
    {
        if (holderOf(gameId) == TAB_ID)
            HaxeFolioApp.valueStorage.remove(key(gameId));
    }

    /** The tab holding an unexpired lease of game `gameId`, or null **/
    private static function holderOf(gameId:Int):Null<String>
    {
        var serialized:Null<String> = HaxeFolioApp.valueStorage.read(key(gameId));
        if (serialized == null)
            return null;

        var parts:Array<String> = serialized.split(";");
        var renewedAtMs:Float = parts.length == 2 ? Std.parseFloat(parts[1]) : Math.NaN;
        if (Math.isNaN(renewedAtMs) || Date.now().getTime() - renewedAtMs > EXPIRY_MS)
            return null;

        return parts[0];
    }

    private static function key(gameId:Int):String
    {
        return LocalStorageKey.BOT_GAME_LEASE_PREFIX + "." + Std.string(gameId);
    }
}
