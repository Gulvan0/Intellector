package client.auth;

using StringTools;

class IdentitySerializer
{
    public static function serialize(identity:Identity):String
    {
        return switch identity {
            case Player(login, nickname): login + "/" + nickname;
            case Guest(guestId) if (guestId != null): '_$guestId';
            default: "_";
        }
    }

    public static function deserialize(serializedIdentity:String):Identity
    {
        if (serializedIdentity == "_")
            return Guest(null);

        if (serializedIdentity.startsWith("_"))
            return Guest(Std.parseInt(serializedIdentity.substr(1)));

        var parts:Array<String> = serializedIdentity.split("/");
        if (Lambda.empty(parts))
            return Guest(null);

        return Player(parts[0], parts[1] ?? parts[0]);
    }
}
