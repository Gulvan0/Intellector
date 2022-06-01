package utils;
using utils.StringUtils;
using StringTools;

class CharIterator 
{
    private var s:String;
    private var length:Int;
    private var i:Int;

    public function hasNext():Bool
    {
        return i < length;
    }

    public function next():String 
    {
        return s.charAt(i++);
    }

    public function new(s:String) 
    {
        this.s = s;
        this.length = s.length;
        this.i = 0;
    }
}

class StringUtils
{
    public static function iterator(s:String):CharIterator
    {
        return new CharIterator(s);
    }

    public static inline function isAlpha(char:String):Bool
    {
        return (char.fastCodeAt(0) >= 'a'.code && char.fastCodeAt(0) <= 'z'.code) || (char.fastCodeAt(0) >= 'A'.code && char.fastCodeAt(0) <= 'Z'.code);
    }

    public static inline function isNumeric(char:String):Bool
    {
        return char.fastCodeAt(0) >= '0'.code && char.fastCodeAt(0) <= '9'.code;
    }

    public static inline function isAlphaNumeric(char:String):Bool 
    {
        return isNumeric(char) || isAlpha(char);
    }

    public static inline function isLowerCase(char:String):Bool  
    {
        return char.fastCodeAt(0) >= 'a'.code && char.fastCodeAt(0) <= 'z'.code;
    }

    public static inline function isUpperCase(char:String):Bool  
    {
        return char.fastCodeAt(0) >= 'A'.code && char.fastCodeAt(0) <= 'Z'.code;
    }

    public static inline function asFrankenstein(str:String):String 
    {
        var converted:String = "";
        for (letter in iterator(str.toLowerCase()))
            if (letter.isAlphaNumeric())
                converted += letter;
        return converted;
    }

    public static inline function asPhrase(str:String):String 
    {
        var converted:String = "";
        var i:Int = 0;
        for (letter in iterator(str))
        {
            if (i == 0)
                converted += letter.toUpperCase();
            else if (letter == "_")
                converted += " ";
            else if (letter.isUpperCase())
                converted += " " + letter.toLowerCase();
            else
                converted += letter;
            i++;
        }
        return converted;
    }
}