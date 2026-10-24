package client.storage;

import client.auth.SavedCredentials;
import js.Cookie;

/**
    Carries the previous version's `saved_login` / `saved_password` cookies over to the saved
    credentials in localStorage. The cookie doesn't tell whether the user asked to be remembered,
    so the migrated credentials are always remembered.
**/
class CredentialsMigration
{
    private static inline final LOGIN_COOKIE:String = "saved_login";
    private static inline final PASSWORD_COOKIE:String = "saved_password";

    public static function run():Void
    {
        var login:Null<String> = Cookie.get(LOGIN_COOKIE);
        var password:Null<String> = Cookie.get(PASSWORD_COOKIE);

        Cookie.remove(LOGIN_COOKIE, "/");
        Cookie.remove(PASSWORD_COOKIE, "/");

        // credentials saved by this version are newer than the cookies
        if (login == null || password == null || SavedCredentials.getSavedLogin() != null)
            return;

        SavedCredentials.save(login, password, true);
    }
}
