package net;

class LoginManager
{
    public static var login:String;
    public static var password:String;

    public static function signin(login:String, password:String) 
    {
        LoginManager.login = login;
        LoginManager.password = password;
        Networker.emitEvent(Login(login, password));
    }

    public static function register(login:String, password:String) 
    {
        LoginManager.login = login;
        LoginManager.password = password;
        Networker.emitEvent(Register(login, password));
    }

    public static function isPlayer(suspectedLogin:String)
    {
        return login.toLowerCase() == suspectedLogin.toLowerCase();
    }
}