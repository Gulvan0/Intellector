package utils;

class TimeControl
{
    public static inline function numRep(v:Int)
    {
        return v < 10? '0$v' : '$v';
    }

    public static function secsToString(secs:Float) 
    {
        var secsRounded:Int = Math.round(secs);
        var secsLeft:Int = secsRounded % 60;
        var minsLeft:Int = cast (secsRounded - secsLeft)/60;
        var minRepresentation = numRep(minsLeft);
        var secRepresentation = numRep(secsLeft);

        var str:String = '$minRepresentation:$secRepresentation';
        if (secs < 10)
            str += '${secs - secsRounded}'.substr(1, 3);
        return str;    
    }
}