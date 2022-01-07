package;

import dict.Language;

enum Markup 
{
    None;
    Side;
    Over;
}

class Preferences
{
    public static var instance:Preferences;
    private static var FIVE_YEARS = 60 * 60 * 24 * 365 * 5;

    public static function initSettings() 
    {
        instance = new Preferences(); 
        if (Cookie.exists("markup"))
            markup = Markup.createByName(Cookie.get("markup"));
        if (Cookie.exists("lang"))
            lang = Language.createByName(Cookie.get("lang"));
    }

    public var markup(default, set):Markup = Over;
    public var language(default, set):Language = EN;

    public function set_markup(v:Markup):Markup
    {
        Cookie.set("markup", v.getName(), FIVE_YEARS);
        return markup = v;
    }

    public function set_language(v:Language):Language
    {
        Cookie.set("lang", v.getName(), FIVE_YEARS);
        return lang = v;
    }
}