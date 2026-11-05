package client.storage;

import js.Browser;

/**
    The API version of the server the client last talked to, in localStorage, read by the loader in
    `index.html` (under the same key) to pick the client folder to load.
**/
class ServerApiVersionStorage
{
    private static inline final KEY:String = "intellector.api_version";

    public static function save(apiVersion:Int):Void
    {
        try
        {
            Browser.window.localStorage.setItem(KEY, Std.string(apiVersion));
        }
        catch (_)
        {
        }
    }
}
