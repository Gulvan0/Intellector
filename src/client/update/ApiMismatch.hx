package client.update;

import client.storage.ServerApiVersionStorage;
import js.Browser;
import net.ws.PubSub;

class ApiMismatch
{
    /** The server refused the connection over the API version: remembers the version it asked for and reloads so the loader picks the matching client **/
    public static function onConnectionClosed(code:Int, reason:String):Void
    {
        if (code != PubSub.API_MISMATCH_CLOSE_CODE)
            return;

        var serverApiVersion:Null<Int> = Std.parseInt(reason);
        if (serverApiVersion == null || serverApiVersion == Config.API_VERSION)
            return;

        ServerApiVersionStorage.save(serverApiVersion);
        Browser.location.reload();
    }
}
