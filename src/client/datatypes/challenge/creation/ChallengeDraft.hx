package client.datatypes.challenge.creation;

/**
    The challenge creation form's raw values, valid or not: what the form opens with and what is
    remembered between visits. Values a variant doesn't use (e.g. the login while Open is selected)
    are kept, so switching back restores them.
**/
class ChallengeDraft
{
    public var type:ChallengeType = DIRECT;
    public var visibility:OpenChallengeVisibility = PUBLIC;
    public var calleeKind:CalleeKind = PLAYER;
    public var calleeLogin:String = "";
    public var calleeGuestNumber:String = "";
    public var timed:Bool = true;
    public var startSeconds:Int = 300;
    public var incrementSeconds:Int = 0;
    public var rated:Bool = false;
    public var callerColor:CallerColorChoice = RANDOM;
    public var positionMode:StartingPositionMode = DEFAULT;

    /** The last applied custom position, as SIP **/
    public var customSip:Null<String> = null;

    public function new() {}
}
