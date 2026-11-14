package net.models.game.archive;

import hxjsonast.Json;
import hxjsonast.Printer;

/** For fields holding a JSON value as text, passed through as is **/
class RawJson
{
    public static function write(json:String):String
    {
        return json;
    }

    public static function parse(value:Json, name:String):String
    {
        return Printer.print(value);
    }
}
