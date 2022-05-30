package utils;

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
}