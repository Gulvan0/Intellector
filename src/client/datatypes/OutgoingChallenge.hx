package client.datatypes;

import intellectorboard.position.Position;

/**
    A challenge the current user has sent and that is still pending.
**/
class OutgoingChallenge
{
    public final id:Int;
    /** Null for an open challenge **/
    public final calleeLogin:Null<String>;
    /** Null for an open challenge **/
    public final calleeNickname:Null<String>;
    public final timeControl:TimeControl;
    public final timeControlKind:TimeControlKind;
    public final rated:Bool;

    /**
        The colour the current user plays once it's accepted.
    **/
    public final ownColor:ChallengeAcceptorColor;

    /**
        The position the game starts from, or null for the default one.
    **/
    public final customStartingPosition:Null<Position>;

    public function new(id:Int, calleeLogin:Null<String>, calleeNickname:Null<String>, timeControl:TimeControl, timeControlKind:TimeControlKind, rated:Bool, ownColor:ChallengeAcceptorColor, customStartingPosition:Null<Position>)
    {
        this.id = id;
        this.calleeLogin = calleeLogin;
        this.calleeNickname = calleeNickname;
        this.timeControl = timeControl;
        this.timeControlKind = timeControlKind;
        this.rated = rated;
        this.ownColor = ownColor;
        this.customStartingPosition = customStartingPosition;
    }
}
