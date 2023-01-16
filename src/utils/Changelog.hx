package utils;

import haxe.Resource;
import haxe.Json;
import dict.Language;

private class Entry 
{
    public final date:String;
    public final descMap:Map<Language, String>;

    public function getLength():Int
    {
        //+2 for the separating dot and space
        return date.length + 2 + descMap[Preferences.language.get()].length;
    }

    public function format():String
    {
        return '<b>$date.</b> ${descMap[Preferences.language.get()]}';
    }

    public function new(date:String)
    {
        this.date = date;
        this.descMap = [];
    }
}

class Changelog
{
    private static var changelog:Array<Entry> = [];

    public static function init() 
    {
        var raw:Dynamic = Json.parse(Resource.getString("changelog"));
        for (rawEntry in cast(raw, Array<Dynamic>))
        {
            var entry:Entry = new Entry(Reflect.field(rawEntry, "date"));
            for (language in Language.createAll())
                entry.descMap.set(language, Reflect.field(rawEntry, language.getName()));
            changelog.push(entry);
        }
    }

    public static function getFirstLength():Int
    {
        return changelog[0].getLength();
    }

    public static function getFirst():String
    {
        return changelog[0].format();
    }

    public static function getAll():String
    {
        return changelog.map(x -> x.format()).join('<br>');
    }
}