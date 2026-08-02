package;

using StringTools;

class Config
{
    public static var minServerBuild:Int = 1745671032;

    #if debug

    public static var base_url:String = "https://localhost:8443";
    public static var actualPathPrefix:Null<String> = null;
    public static var prevPathPrefix:Null<String> = null;

    #else

    public static var base_url:String = "https://play-intellector.ru:8443";
    public static var actualPathPrefix:Null<String> = "/";
    public static var prevPathPrefix:Null<String> = "/exgame";

    #end

    public static function getWebsocketUrl():String
    {
        return base_url.replace("http", "ws") + "/ws";
    }
}
