package client.tabs;

import js.Syntax;
import js.lib.Promise;

/**
    Which of the browser's tabs computes the bot's moves in a game: the one holding the game's Web Lock, which the
    browser frees when that tab goes away. Where Web Locks are unavailable (a page served over plain HTTP), tabs don't
    coordinate: every tab gets the lease, and the server rejects all plies but the first.
**/
class BotGameLease
{
    /** How long to wait before asking again for a lease another tab holds **/
    public static inline final RETRY_INTERVAL_MS:Int = 6000;

    private static inline final LOCK_NAME_PREFIX:String = "intellector.bot_game.";

    /** `onResult` gets the function releasing the lease of game `gameId`, or null if another tab holds it **/
    public static function tryAcquire(gameId:Int, onResult:(release:Null<Void->Void>)->Void):Void
    {
        var locks:Null<LockManager> = Syntax.code("navigator.locks");
        if (locks == null)
        {
            onResult(() -> {});
            return;
        }

        locks.request(LOCK_NAME_PREFIX + Std.string(gameId), {ifAvailable: true}, lock -> {
            if (lock == null)
            {
                onResult(null);
                return null;
            }

            return new Promise<Any>((resolve, _) -> {
                onResult(() -> resolve(null));
            });
        });
    }
}

private extern class LockManager
{
    /** Holds the lock until the promise `callback` returns settles; `callback` gets null if the lock is taken **/
    public function request(name:String, options:{ifAvailable:Bool}, callback:Null<Any>->Null<Promise<Any>>):Promise<Any>;
}
