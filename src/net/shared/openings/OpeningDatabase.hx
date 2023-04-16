package net.shared.openings;

class OpeningDatabase
{
    private static var openings:Map<String, Opening> = [];

    public static function generate(openingsJSON:String) 
    {
        //TODO: Parse, don't forget about symmetry
    }

    public static function get(sip:String):Null<Opening>
    {
        return openings.get(sip);
    }
}