package client.datatypes.challenge;

import client.datatypes.game.PlayerRating;
import client.datatypes.timecontrol.TimeControl;
import client.datatypes.timecontrol.TimeControlKind;
import intellectorboard.position.Position;

/** A public challenge anyone may accept, as listed **/
class OpenChallenge
{
    public final id:Int;
    /** A login, or a guest's `_<id>` **/
    public final callerRef:String;
    public final callerNickname:String;
    /** The rating the caller would play at; null for a casual challenge or a guest **/
    public final callerRating:Null<PlayerRating>;
    public final timeControl:TimeControl;
    public final timeControlKind:TimeControlKind;
    public final rated:Bool;
    /** The colour whoever accepts plays **/
    public final acceptorColor:ChallengeAcceptorColor;
    /** Null for the default one **/
    public final customStartingPosition:Null<Position>;

    public function new(id:Int, callerRef:String, callerNickname:String, callerRating:Null<PlayerRating>, timeControl:TimeControl, timeControlKind:TimeControlKind, rated:Bool, acceptorColor:ChallengeAcceptorColor, customStartingPosition:Null<Position>)
    {
        this.id = id;
        this.callerRef = callerRef;
        this.callerNickname = callerNickname;
        this.callerRating = callerRating;
        this.timeControl = timeControl;
        this.timeControlKind = timeControlKind;
        this.rated = rated;
        this.acceptorColor = acceptorColor;
        this.customStartingPosition = customStartingPosition;
    }
}
