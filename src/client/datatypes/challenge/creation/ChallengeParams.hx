package client.datatypes.challenge.creation;

import client.datatypes.timecontrol.TimeControl;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

/**
    A challenge about to be created.
**/
class ChallengeParams
{
    public final target:ChallengeTarget;
    public final timeControl:TimeControl;
    public final rated:Bool;

    /** The colour the creator plays, or null for a random one **/
    public final callerColor:Null<PieceColor>;

    /** The position the game starts from, or null for the default one **/
    public final customStartingPosition:Null<Position>;

    public function new(target:ChallengeTarget, timeControl:TimeControl, rated:Bool, callerColor:Null<PieceColor>, customStartingPosition:Null<Position>)
    {
        this.target = target;
        this.timeControl = timeControl;
        this.rated = rated;
        this.callerColor = callerColor;
        this.customStartingPosition = customStartingPosition;
    }
}
