package analysis;

class MathUtils 
{
    public static function avg(num1:Float, num2:Float):Float
    {
        return (num1 + num2) / 2;    
    } 
    
    public static function pround(num:Float, order:Int):Float
    {
        var shiftMultiplier = Math.pow(10, order);
        return Math.round(num * shiftMultiplier) / shiftMultiplier;
    }
    
    public static function proundStr(num:Float, order:Int):String
    {
        var shiftMultiplier = Math.pow(10, order);
        var shiftedNum = Math.round(num * shiftMultiplier);
        var raw = "" + shiftedNum;

        if (shiftedNum <= -100 || shiftedNum >= 100)
            return raw.substr(0, raw.length - 2) + "." + raw.substr(raw.length - 2, 2);
        else if (shiftedNum <= -10 || shiftedNum >= 10)
            return raw.substr(0, raw.length - 2) + "0." + raw.substr(raw.length - 2, 2);
        else
            return raw.substr(0, raw.length - 1) + "0.0" + raw.substr(raw.length - 1, 1);
    }
}