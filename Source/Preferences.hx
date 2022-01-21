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

    public var markup(default, set):Markup = Over;
    public var language(default, set):Language = EN;
    public var premoveEnabled(default, set):Bool = false;
    public var branchingTabType(default, set):BranchingTabType = Tree; //TODO: Add new options to settings screen

    public function set_markup(v:Markup):Markup
    {
        Cookie.set("markup", v.getName(), FIVE_YEARS);
        return markup = v;
    }

    public function set_language(v:Language):Language
    {
        Cookie.set("lang", v.getName(), FIVE_YEARS);
        return language = v;
    }

    public function set_premoveEnabled(v:Bool):Bool
    {
        Cookie.set("premoveEnabled", v? "true" : "false", FIVE_YEARS);
        return premoveEnabled = v;
    }

    public function set_branchingTabType(v:BranchingTabType):BranchingTabType
    {
        Cookie.set("branchingTabType", v.getName(), FIVE_YEARS);
        return branchingTabType = v;
    }

    public function new()
    {

    }
}