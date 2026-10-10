package client.formatters;

class ClockFormatters
{
    /** `mm:ss`, or `h:mm:ss` from an hour on; whole seconds, rounded up **/
    public static function formatRemainingTime(remainingMs:Float):String
    {
        var totalSeconds:Int = Math.ceil(remainingMs / 1000);
        var hours:Int = Std.int(totalSeconds / 3600);
        var minutes:Int = Std.int(totalSeconds / 60) % 60;
        var seconds:Int = totalSeconds % 60;

        var minutesAndSeconds:String = '${StringTools.lpad(Std.string(minutes), "0", 2)}:${StringTools.lpad(Std.string(seconds), "0", 2)}';
        return hours > 0 ? '$hours:$minutesAndSeconds' : minutesAndSeconds;
    }
}
