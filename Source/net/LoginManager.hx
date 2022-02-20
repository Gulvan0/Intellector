package net;

using StringTools;

class LoginManager
{
    public static var login:String;
    public static var password:String;
    private static var lastAuto:Bool;

    public static function wasLastSignInAuto():Bool 
    {
        return lastAuto;
    }

    public static function signin(login:String, password:String, auto:Bool) 
    {
        LoginManager.login = login;
        LoginManager.password = password;
        LoginManager.lastAuto = auto;
        Networker.emitEvent(Login(login, password));
    }

    public static function register(login:String, password:String) 
    {
        LoginManager.login = login;
        LoginManager.password = password;
        LoginManager.lastAuto = false;
        Networker.emitEvent(Register(login, password));
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