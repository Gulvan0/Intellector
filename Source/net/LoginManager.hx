package net;

import browser.CredentialCookies;
using StringTools;

class LoginManager
{
    public static var login:Null<String>;
    public static var password:Null<String>;

    public static function signin(login:String, password:String, auto:Bool) 
    {
        LoginManager.login = login;
        LoginManager.password = password;
        Networker.eventQueue.addHandler(callback);
        Networker.emitEvent(Login(login, password));
    }

    public static function register(login:String, password:String) 
    {
        LoginManager.login = login;
        LoginManager.password = password;
        Networker.emitEvent(Register(login, password));
    }

    private static function callback(event:ServerEvent)
    {
        switch event
        {
            case LoginResult(success), RegisterResult(success):
                Networker.eventQueue.removeHandler(callback);
                if (!success)
                {
                    LoginManager.login = null;
                    LoginManager.password = null;
                    CredentialCookies.removeLoginDetails();
                }
            default:
        }
    }

    public static function isPlayer(suspectedLogin:String)
    {
        return login.toLowerCase() == suspectedLogin.toLowerCase();
    }

    public static function isPlayerGuest():Bool
    {
        return login.startsWith("guest_");
    }
}