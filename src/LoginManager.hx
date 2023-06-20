package;

import net.shared.utils.PlayerRef;
import net.shared.dataobj.ChallengeData;
import gfx.scene.SceneManager;
import net.shared.dataobj.SignInResult;
import net.shared.message.ServerEvent;
import net.Networker;
import haxe.crypto.Md5;
import browser.CredentialCookies;
using StringTools;

enum CredentialsPreservation
{
    LongTerm;
    ShortTerm;
    None;
}

class LoginManager
{
    private static var login:Null<String>;
    private static var password:Null<String>;

    public static function getLogin():Null<String>
    {
        return login;
    }

    public static function getPassword():Null<String>
    {
        return password;
    }
    
    public static function getRef():PlayerRef
    {
        return login ?? "_" + Networker.getSessionID();
    }

    public static function imitateLoggedState(?assumedLogin:String = "Tester")
    {
        login = assumedLogin;
    }

    public static function assignCredentials(login:String, password:String, preservation:CredentialsPreservation)
    {
        LoginManager.login = login;
        LoginManager.password = password;

        if (preservation == LongTerm)
            CredentialCookies.saveLoginDetails(login, password, false);
        else if (preservation == ShortTerm)
            CredentialCookies.saveLoginDetails(login, password, true);

        GlobalBroadcaster.broadcast(LoggedIn);
    }

    public static function removeCredentials()
    {
        LoginManager.login = null;
        LoginManager.password = null;

        CredentialCookies.removeLoginDetails();
        GlobalBroadcaster.broadcast(LoggedOut);
    }

    public static function isLogged():Bool
    {
        return login != null;
    }

    public static function isPlayer(suspectedRef:PlayerRef):Bool
    {
        switch suspectedRef.concretize() 
        {
            case Normal(refLogin):
                return login != null && login.toLowerCase() == refLogin.toLowerCase();
            case Guest(guestID):
                return Networker.getSessionID() == Std.parseInt(guestID);
            case Bot(botHandle):
                return false;
        }
    }
}