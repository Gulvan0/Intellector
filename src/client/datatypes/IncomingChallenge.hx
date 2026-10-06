package client.datatypes;

import intellectorboard.position.Position;

/**
    A direct challenge addressed to the current user, seen from their side.
**/
class IncomingChallenge
{
    public final id:Int;
    public final callerLogin:String;
    public final callerNickname:String;
    public final timeControl:TimeControl;
    public final timeControlKind:TimeControlKind;
    public final rated:Bool;

    /**
        The colour the current user plays if they accept.
    **/
    public final acceptorColor:ChallengeAcceptorColor;

    /**
        The position the game starts from, or null for the default one.
    **/
    public final customStartingPosition:Null<Position>;

    public function new(id:Int, callerLogin:String, callerNickname:String, timeControl:TimeControl, timeControlKind:TimeControlKind, rated:Bool, acceptorColor:ChallengeAcceptorColor, customStartingPosition:Null<Position>)
    {
        this.id = id;
        this.callerLogin = callerLogin;
        this.callerNickname = callerNickname;
        this.timeControl = timeControl;
        this.timeControlKind = timeControlKind;
        this.rated = rated;
        this.acceptorColor = acceptorColor;
        this.customStartingPosition = customStartingPosition;
    }
}
