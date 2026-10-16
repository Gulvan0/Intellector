package client.formatters;

/**
    Plural forms. A counted locale key has one variant per plural form of its language:
    `<key>.one`, `<key>.few` (Russian only) and `<key>.many`.
**/
class Plurals
{
    /** `count`'s plural form in `language`: `one`, `few` or `many` **/
    public static function form(count:Int, language:String):String
    {
        if (language != "ru")
            return count == 1 ? "one" : "many";

        var lastDigit:Int = count % 10;
        var lastTwoDigits:Int = count % 100;
        if (lastDigit == 1 && lastTwoDigits != 11)
            return "one";
        if (lastDigit >= 2 && lastDigit <= 4 && (lastTwoDigits < 12 || lastTwoDigits > 14))
            return "few";
        return "many";
    }

    /** The variant of the counted `key` for `count` in `language` **/
    public static function key(key:String, count:Int, language:String):String
    {
        return '$key.${form(count, language)}';
    }
}
