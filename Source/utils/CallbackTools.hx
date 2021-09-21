package utils;

class CallbackTools 
{
    public static function expand(func:Void->Void):Dynamic->Void
    {
        return arg -> {func();};
    }  
}