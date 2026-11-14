package;

class Config
{
    /** Bumped on a breaking API change; must equal the server's **/
    public static inline final API_VERSION:Int = 3;

    #if debug

    public static final BASE_URL:String = debugBaseUrl();

    /** A page served over plain HTTP (another device, or a phone reaching `localhost` through `adb reverse`) cannot trust the dev server's self-signed certificate, so it uses the server's plain-HTTP port **/
    private static function debugBaseUrl():String
    {
        var hostname:String = js.Browser.location.hostname;
        if (js.Browser.location.protocol == "https:")
            return 'https://$hostname:8443';
        return 'http://$hostname:8080';
    }

    #else

    /** Set by `index.html`, which needs the production address before any client is loaded **/
    public static final BASE_URL:String = js.Syntax.code("window.API_BASE_URL");

    #end

    public static function getWebsocketUrl():String
    {
        return "ws" + BASE_URL.substr("http".length) + "/ws?api=" + API_VERSION;
    }
}
