package engine;

import engine.bots.StandardAnaconda;

class BotFactory
{
    public static function build(handle:String):Bot
    {
        var parts:Array<String> = handle.split("_");
        var slug:String = parts[0];
        var params:Array<String> = parts.slice(1);

        switch slug
        {
            case "stconda":
                var depth:Int = 14;
                if (!Lambda.empty(params))
                {
                    var parsedDepth = Std.parseInt(params[0]);
                    if (parsedDepth != null && parsedDepth > 0 && parsedDepth < 20)
                        depth = parsedDepth;
                }
                return new StandardAnaconda(botNameBySplittedHandle(slug, params), depth);
            default:
                throw 'Cannot find bot by handle: $handle';
        }
    }

    public static function botNameByHandle(handle:String):String
    {
        var parts:Array<String> = handle.split("_");
        var slug:String = parts[0];
        var params:Array<String> = parts.slice(1);

        return botNameBySplittedHandle(slug, params);
    }

    private static function botNameBySplittedHandle(slug:String, params:Array<String>):String
    {
        var actualName:String = switch slug 
        {
            case "stconda": "Anaconda";
            default: "Unknown";
        }
        return actualName + " (Bot)";
    }
}