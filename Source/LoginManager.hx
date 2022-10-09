package;

import net.shared.ChallengeData;
import serialization.GameLogParser;
import gfx.SceneManager;
import net.shared.SignInResult;
import net.shared.ServerEvent;
import haxe.crypto.Md5;
import browser.CredentialCookies;
using StringTools;

class LoginManager
{
    private static inline final onetimeLoginPrefix:String = "guest_";

    private static var login:Null<String>;
    private static var password:Null<String>;

    public static function getLogin():String
    {
        return login;
    }

    public static function getPassword():Null<String>
    {
        return password;
    }

    public static function imitateLoggedState(?assumedLogin:String = "Tester")
    {
        login = assumedLogin;
    }

    public static function signin(login:String, password:String, remember:Null<Bool>, onSuccess:Void->Void, onFail:Void->Void) 
    {
        Networker.addHandler(responseHandler.bind(login, password, remember, onSuccess, onFail));
        Networker.emitEvent(Login(login, password));
    }

    public static function register(login:String, password:String, remember:Null<Bool>, onSuccess:Void->Void, onFail:Void->Void) 
    {
        Networker.addHandler(responseHandler.bind(login, password, remember, onSuccess, onFail));
        Networker.emitEvent(Register(login, password));
    }

    public static function generateOneTimeCredentials()
    {
        if (isLogged())
            throw "Already logged, but trying to generate credentials";

        login = onetimeLoginPrefix + Math.ceil(Math.random() * 100000);
        password = Md5.encode(Std.string(Math.random()));
        CredentialCookies.saveLoginDetails(login, password, true);
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
            case LoginResult(result), RegisterResult(result):
                processSignInResult(login, password, remember, onSuccess, onFail, result);
                return true;
            default:
                return false;
        }
    }

    private static function processSignInResult(login:String, password:String, remember:Null<Bool>, onSuccess:Void->Void, onFail:Void->Void, result:SignInResult)
    {
        switch result 
        {
            case Success(incomingChallenges):
                onSuccessfulSignIn(login, password, remember, incomingChallenges, onSuccess);
            case ReconnectionNeeded(incomingChallenges, gameID, timeData, currentLog):
                onSuccessfulSignIn(login, password, remember, incomingChallenges, onSuccess);
                var parsedData:GameLogParserOutput = GameLogParser.parse(currentLog);
                SceneManager.toScreen(LiveGame(gameID, Ongoing(parsedData, timeData, null)));
            case Fail:
                CredentialCookies.removeLoginDetails();
                onFail();
        }
    }

    private static function onSuccessfulSignIn(login:String, password:String, remember:Null<Bool>, incomingChallenges:Array<ChallengeData>, callback:Void->Void)
    {
        LoginManager.login = login;
        LoginManager.password = password;
        if (remember != null)
            CredentialCookies.saveLoginDetails(login, password, !remember);
        GlobalBroadcaster.broadcast(LoggedIn(incomingChallenges));
        callback();
    }

    public static function isLogged():Bool
    {
        return login != null;
    }

    public static function isPlayer(suspectedLogin:String)
    {
        return login != null && login.toLowerCase() == suspectedLogin.toLowerCase();
    }

    public static function isPlayerGuest():Bool
    {
        return login.startsWith(onetimeLoginPrefix);
    }
}