package engine.hxconda.search.budget;

/** The `performance` clock of the browser **/
@:native("performance")
extern class Clock
{
    public static function now():Float;
}
