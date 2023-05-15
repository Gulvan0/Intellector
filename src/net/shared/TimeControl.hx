package net.shared;

class TimeControl 
{
    public final startSecs:Int;
    public final incrementSecs:Int;

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

    public static function correspondence():TimeControl
    {
        return new TimeControl(0, 0);
    }

    public static function normal(startMins:Float, incrementSecs:Int):TimeControl
    {
        return new TimeControl(Math.round(startMins * 60), incrementSecs);
    }

    public function isCorrespondence():Bool
    {
        return getType() == Correspondence;
    }

    public function getDisplayName(ru:Bool):String 
    {
        if (isCorrespondence())
            return ru? 'По переписке' : 'Correspondence';
        else if (startSecs % 60 == 0)
            return '${startSecs/60}+$incrementSecs';
        else if (startSecs > 60)
            return '${Math.floor(startSecs/60)}m${startSecs % 60}s+$incrementSecs';
        else
            return '${startSecs % 60}s+$incrementSecs';
    }

    public function toString():String
    {
        return getDisplayName(false);
    }

    public function getType():TimeControlType
    {
        var determinant:Int = startSecs + 40 * incrementSecs;
        if (determinant == 0)
            return Correspondence;
        else if (determinant < 1 * 60)
            return Hyperbullet;
        else if (determinant < 3 * 60)
            return Bullet;
        else if (determinant < 10 * 60)
            return Blitz;
        else if (determinant < 60 * 60)
            return Rapid;
        else 
            return Classic;
    }

    public function copy():TimeControl
    {
        return new TimeControl(startSecs, incrementSecs);
    }

    public function new(startSecs:Int, incrementSecs:Int)
    {
        this.startSecs = startSecs;
        this.incrementSecs = incrementSecs;
    }
}