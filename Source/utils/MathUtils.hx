package utils;

class MathUtils 
{
    public static function scaleLike(defaultValue:Float, defaultMeasure:Float, scaledMeasure:Float) 
    {
        return defaultValue * scaledMeasure / defaultMeasure;
    }
    
    public static function intScaleLike(defaultValue:Float, defaultMeasure:Float, scaledMeasure:Float) 
    {
        return Math.round(defaultValue * scaledMeasure / defaultMeasure);
    }
}