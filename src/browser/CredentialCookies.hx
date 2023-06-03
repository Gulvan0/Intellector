package browser;

import dict.Dictionary;
import js.Browser;
import js.html.URLSearchParams;
import js.Cookie;

class CredentialCookies
{
    private static var LOGIN_COOKIE:String = "saved_login";
    private static var PASSWORD_COOKIE:String = "saved_password";

    public static function hasLoginDetails():Bool
    {
        return Cookie.exists(LOGIN_COOKIE) && Cookie.exists(PASSWORD_COOKIE);
    }

    public static function getLogin():String
    {
        return Cookie.get(LOGIN_COOKIE);
    }

    public static function getPassword():String
    {
        return Cookie.get(PASSWORD_COOKIE);
    }

    public static function saveLoginDetails(?login:String, ?password:String, expirable:Bool = false) 
    {
        var duration:Null<Int> = expirable? 60 * 60 * 6 : 60 * 60 * 24 * 365 * 5;
        Cookie.set(LOGIN_COOKIE, login ?? LoginManager.getLogin(), duration, "/");
        Cookie.set(PASSWORD_COOKIE, password ?? LoginManager.getPassword(), duration, "/");
    }

    public static function removeLoginDetails() 
    {
        while (Cookie.exists(LOGIN_COOKIE))
        {
            Cookie.remove(LOGIN_COOKIE);
            Cookie.remove(LOGIN_COOKIE, "/");
        }

        while (Cookie.exists(PASSWORD_COOKIE))
        {
            Cookie.remove(PASSWORD_COOKIE);
            Cookie.remove(PASSWORD_COOKIE, "/");
        }
    }
}