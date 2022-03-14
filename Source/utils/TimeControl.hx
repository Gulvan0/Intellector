package utils;

class TimeControl
{
    public static inline function numRep(v:Int)
    {
        return v < 10? '0$v' : '$v';
    }

    public static function secsToString(secs:Float) 
    {
        var secsRounded:Int = Math.floor(secs);
        var secsLeft:Int = secsRounded % 60;
        var minsLeft:Int = cast (secsRounded - secsLeft)/60;
        var minRepresentation = numRep(minsLeft);
        var secRepresentation = numRep(secsLeft);

        var str:String = '$minRepresentation:$secRepresentation';
        if (secs < 10)
        {
            var hundredths:String = '${Math.floor((secs - secsRounded) * 100)}';
            while (hundredths.length < 2)
                hundredths += '0';
            str += "." + hundredths;
        }
        return str;    
    }

    public var startSecs:Int;
    public var bonusSecs:Int;

    public function toString() 
    {
        if (startSecs % 60 == 0)
        {
            var startMins:Int = Math.round(startSecs / 60);
            return '$startMins+$bonusSecs';
        }
        else 
            return '$startSecs' + 's+$bonusSecs';
    }

    public function new(startSecs:Int, bonusSecs:Int)
    {
        this.startSecs = startSecs;
        this.bonusSecs = bonusSecs;
    }
}