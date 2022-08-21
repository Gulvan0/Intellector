package net;

import browser.CredentialCookies;
using StringTools;

class LoginManager
{
    public static var login:Null<String>;
    public static var password:Null<String>;

    public static function signin(login:String, password:String, remember:Null<Bool>, onSuccess:Void->Void, onFail:Void->Void) 
    {
        Networker.eventQueue.addHandler(responseHandler.bind(login, password, remember, onSuccess, onFail));
        Networker.emitEvent(Login(login, password));
    }

    public static function register(login:String, password:String, remember:Null<Bool>, onSuccess:Void->Void, onFail:Void->Void) 
    {
        Networker.eventQueue.addHandler(responseHandler.bind(login, password, remember, onSuccess, onFail));
        Networker.emitEvent(Register(login, password));
    }

    public static function logout()
    {
        CredentialCookies.removeLoginDetails();
        Networker.emitEvent(LogOut);
        GlobalBroadcaster.broadcast(LoggedOut);
    }

    private static function responseHandler(login:String, password:String, remember:Null<Bool>, onSuccess:Void->Void, onFail:Void->Void, event:ServerEvent) 
    {
        switch event
        {
            case LoginResult(success), RegisterResult(success):
                if (success)
                {
                    LoginManager.login = login;
                    LoginManager.password = password;
                    if (remember != null)
                        CredentialCookies.saveLoginDetails(login, password, !remember);
                    GlobalBroadcaster.broadcast(LoggedIn);
                    onSuccess();
                }
                else
                {
                    CredentialCookies.removeLoginDetails();
                    onFail();
                }
                return true;
            default:
                return false;
        }
    }

    public static function isPlayer(suspectedLogin:String)
    {
        return login != null && login.toLowerCase() == suspectedLogin.toLowerCase();
    }

    public static function isPlayerGuest():Bool
    {
        return login.startsWith("guest_");
    }
}