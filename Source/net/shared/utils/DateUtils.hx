package net.shared.utils;

class DateUtils 
{
    public static function dateFromSecs(secs:Float):Date 
    {
        return Date.fromTime(secs * 1000);
    }

    public static function dateFromMs(ms:Float):Date 
    {
        return Date.fromTime(ms);
    }
    
    public static function strDatetimeFromSecs(secs:Float):String
    {
        return dateFromSecs(secs).toString();
    }
    
    public static function strDatetimeFromMs(ms:Float):String
    {
        return dateFromMs(ms).toString();
    }
    
    public static function strDayFromSecs(secs:Float):String
    {
        return DateTools.format(dateFromSecs(secs), "%Y-%m-%d");
    }
    
    public static function strDayFromMs(ms:Float):String
    {
        return DateTools.format(dateFromMs(ms), "%Y-%m-%d");
    }
}