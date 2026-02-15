package;

class Config
{
    public static var minServerBuild: Int = 1745671032;

    #if debug

    public static var base_url: String = "http://localhost/";
    public static var actualPathPrefix: Null<String> = null;
    public static var prevPathPrefix: Null<String> = null;

    #else

    public static var base_url: String = "https://play-intellector.ru/";
    public static var actualPathPrefix: Null<String> = "/";
    public static var prevPathPrefix: Null<String> = "/exgame";

    #end
}
