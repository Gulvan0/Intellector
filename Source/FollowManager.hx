package;

import net.Requests;

class FollowManager 
{
    private static var followedLogin:Null<String> = null;
    
    public static function followPlayer(login:String) 
    {
        if (login == null)
            throw "login can't be null";

        login = login.toLowerCase();

        if (followedLogin == login)
            return;

        followedLogin = login;
        Requests.followPlayer(login);
        GlobalBroadcaster.broadcast(FollowedPlayerUpdated(login));
    }

    public static function stopFollowing()
    {
        if (followedLogin == null)
            return;

        followedLogin = null;
        Networker.emitEvent(StopFollowing);
        GlobalBroadcaster.broadcast(FollowedPlayerUpdated(null));
    }

    public static function isFollowing():Bool
    {
        return followedLogin != null;
    }
    
    public static function getFollowedPlayerLogin():String
    {
        return followedLogin;
    }
}