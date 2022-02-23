package;

import js.Cookie;
import dict.Language;

enum Markup 
{
    None;
    Side;
    Over;
}

enum BranchingTabType
{
    Tree;
    Outline;
    PlainText;
}

class Preferences
{
    public static var instance:Preferences;
    private static var FIVE_YEARS = 60 * 60 * 24 * 365 * 5;

    public static function initSettings() 
    {
        instance = new Preferences(); 
        if (Cookie.exists("markup"))
            instance.markup = Markup.createByName(Cookie.get("markup"));
        if (Cookie.exists("lang"))
            instance.language = Language.createByName(Cookie.get("lang"));
        if (Cookie.exists("premoveEnabled"))
            instance.premoveEnabled = Cookie.get("premoveEnabled") == "true";
        if (Cookie.exists("branchingTabType"))
            instance.branchingTabType = BranchingTabType.createByName(Cookie.get("branchingTabType"));
    }

    public var markup(default, null):Markup = Over;
    public var language(default, null):Language = EN;
    public var premoveEnabled(default, null):Bool = false;
    public var branchingTabType(default, null):BranchingTabType = Tree; //TODO: Add new options to settings screen

    public static function setMarkup(v:Markup)
    {
        Cookie.set("markup", v.getName(), FIVE_YEARS);
        instance.markup = v;
    }

    public static function setLanguage(v:Language)
    {
        Cookie.set("lang", v.getName(), FIVE_YEARS);
        instance.language = v;
    }

    public static function setPremoveEnabled(v:Bool)
    {
        Cookie.set("premoveEnabled", v? "true" : "false", FIVE_YEARS);
        instance.premoveEnabled = v;
    }

    public static function setBranchingTabType(v:BranchingTabType)
    {
        Cookie.set("branchingTabType", v.getName(), FIVE_YEARS);
        instance.branchingTabType = v;
    }

    public function new()
    {

    }
}