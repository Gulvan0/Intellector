package client.logic.watch;

/**
    Reads the login of a player to watch from the nickname the user typed: nicknames differ from
    logins only in capitalisation and extra spaces.
**/
class WatchedNicknameParsing
{
    private static final LOGIN_PATTERN:EReg = ~/^[a-z](_?[a-z0-9]+)+$/;

    /** Null if no login reads so **/
    public static function login(nickname:String):Null<String>
    {
        var login:String = StringTools.replace(nickname, " ", "").toLowerCase();
        return LOGIN_PATTERN.match(login) ? login : null;
    }
}
