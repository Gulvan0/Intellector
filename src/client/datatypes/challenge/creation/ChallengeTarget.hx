package client.datatypes.challenge.creation;

/** Who a challenge being created is meant for **/
@:using(client.datatypes.challenge.creation.ChallengeTarget.ChallengeTargetExtension)
enum ChallengeTarget
{
    Player(login:String);
    Guest(guestId:Int);
    Public;
    LinkOnly;
    Bot;
}

class ChallengeTargetExtension
{
    /** The user ref the server knows the callee by, or null for an open or bot challenge **/
    public static function calleeRef(target:ChallengeTarget):Null<String>
    {
        return switch target {
            case Player(login): login;
            case Guest(guestId): '_$guestId';
            case Public | LinkOnly | Bot: null;
        }
    }
}
