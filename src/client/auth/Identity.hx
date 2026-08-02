package client.auth;

@:using(client.auth.Identity.IdentityExtension)
enum Identity
{
    Player(login:String, nickname:String);
    Guest(guestId:Null<Int>);  // null = unknown
}

class IdentityExtension
{
    public static function getLogin(identity:Identity):Null<String>
    {
        return switch identity {
            case Player(login, _): login;
            default: null;
        }
    }

    public static function isGuest(identity:Identity):Bool
    {
        return identity.match(Guest(_));
    }
}
