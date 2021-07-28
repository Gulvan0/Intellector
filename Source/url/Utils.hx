package url;

import dict.Dictionary;
import js.Browser;
import js.html.URLSearchParams;
import js.Cookie;

class Utils
{
    public static function saveLoginDetails(login:String, password:String) 
    {
        Cookie.set("saved_login", login, 60 * 60 * 24 * 365 * 5, "/");
		Cookie.set("saved_password", password, 60 * 60 * 24 * 365 * 5, "/");
    }

    public static function removeLoginDetails() 
    {
        while (Cookie.exists("saved_login"))
        {
            Cookie.remove("saved_login");
            Cookie.remove("saved_login", "/");
        }

        while (Cookie.exists("saved_password"))
        {
            Cookie.remove("saved_password");
            Cookie.remove("saved_password", "/");
        }
    }

    public static function getShallowSection():Section
    {
        var searcher = new URLSearchParams(Browser.location.search);
        if (searcher.has("id"))
			return Game(Std.parseInt(searcher.get("id")));
        else if (searcher.has("ch"))
            return OpenChallengeInvitation(searcher.get("ch"));
		else
			return Main;
    }

    public static function initSettings() 
    {
        if (Cookie.exists("markup"))
            Field.markup = Markup.createByName(Cookie.get("markup"));
        if (Cookie.exists("lang"))
            Dictionary.lang = Language.createByName(Cookie.get("lang"));
    }
}