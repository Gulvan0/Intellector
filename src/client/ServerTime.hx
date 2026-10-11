package client;

/** The server's current time, as estimated by the source `Main` sets; the local clock until then **/
class ServerTime
{
    private static var source:Void->Float = () -> Date.now().getTime();

    public static function init(source:Void->Float):Void
    {
        ServerTime.source = source;
    }

    /** Unix time, in milliseconds **/
    public static function now():Float
    {
        return source();
    }
}
