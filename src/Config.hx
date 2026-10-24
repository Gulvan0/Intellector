package;

class Config
{
    public static var minServerBuild:Int = 1745671032;

    #if debug

    public static var base_url:String = debugBaseUrl();
    public static var actualPathPrefix:Null<String> = null;
    public static var prevPathPrefix:Null<String> = null;

    #else

    public static var base_url:String = "https://play-intellector.ru:8443";
    public static var actualPathPrefix:Null<String> = "/";
    public static var prevPathPrefix:Null<String> = "/exgame";

    #end

    #if debug
    /** Other devices on the local network cannot trust the dev server's self-signed certificate, so they use its plain-HTTP port **/
    private static function debugBaseUrl():String
    {
        var hostname:String = js.Browser.location.hostname;
        if (hostname == "localhost" || hostname == "127.0.0.1")
            return 'https://$hostname:8443';
        return 'http://$hostname:8080';
    }
    #end

    public static function getWebsocketUrl():String
    {
        return "ws" + base_url.substr("http".length) + "/ws";
    }
}
