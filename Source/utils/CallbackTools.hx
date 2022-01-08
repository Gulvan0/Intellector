package utils;

class CallbackTools 
{
    public static function expand(func:Void->Void):Dynamic->Void
    {
        return arg -> {func();};
    } 

    public static function combineVoid(f1:Void->Void, f2:Void->Void):Void->Void
    {
        return () -> {f1(); f2();};
    }

    public static function combineFirst<T>(f1:T->Void, f2:Void->Void):T->Void
    {
        return (t:T) -> {f1(t); f2();};
    }

    public static function combineSecond<T>(f1:Void->Void, f2:T->Void):T->Void
    {
        return (t:T) -> {f1(); f2(t);};
    } 
}