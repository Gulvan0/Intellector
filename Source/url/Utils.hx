package url;

import net.LoginManager;
import dict.Dictionary;
import js.Browser;
import js.html.URLSearchParams;
import js.Cookie;

class Utils
{

    public static function saveLoginDetails(?login:String, ?password:String, expirable:Bool = false) 
    {
        var duration:Null<Int> = expirable? null : 60 * 60 * 24 * 365 * 5;
        Cookie.set("saved_login", login == null? LoginManager.login : login, duration, "/");
		Cookie.set("saved_password", password == null? LoginManager.password : password, duration, "/");
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
        else if (searcher.has("p"))
            return Profile(searcher.get("p"))
        else
			return Main;
    }
}