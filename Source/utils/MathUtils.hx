package utils;

class MathUtils 
{   
    public static var HALF_SQRT3:Float = Math.sqrt(3) / 2;

    public static function scaleLike(defaultValue:Float, defaultMeasure:Float, scaledMeasure:Float) 
    {
        return defaultValue * scaledMeasure / defaultMeasure;
    }
    
    public static function intScaleLike(defaultValue:Float, defaultMeasure:Float, scaledMeasure:Float) 
    {
        return Math.round(defaultValue * scaledMeasure / defaultMeasure);
    }

    public static function clamp(v:Float, min:Float, max:Float):Float
    {
        if (v < min)
            return min;
        else if (v > max)
            return max;
        else 
            return v;
    }

    /**Inclusive interval (x in [from; to])**/
    public static function randomInt(from:Int, to:Int) 
    {
        return Math.floor(Math.random() * (to - from + 1)) + from;
    }

    public static function randomElement<T>(a:Array<T>):T
    {
        return a[randomInt(0, a.length - 1)];
    }
}