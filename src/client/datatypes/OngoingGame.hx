package client.datatypes;

import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

/** An ongoing game of the current user, seen from their side **/
class OngoingGame
{
    public final id:Int;
    public final opponentNickname:String;
    public final ownColor:PieceColor;
    public final timeControl:TimeControl;
    public final rated:Bool;
    /** Unix time, in milliseconds **/
    public final startedAtMs:Float;
    public final position:Position;
    public final plyCount:Int;
    /** Unix time of the latest move in milliseconds, or null before the first one **/
    public final lastPlyAtMs:Null<Float>;
    /** Null for a correspondence game **/
    public final clock:Null<GameClock>;

    public function new(id:Int, opponentNickname:String, ownColor:PieceColor, timeControl:TimeControl, rated:Bool, startedAtMs:Float, position:Position, plyCount:Int, lastPlyAtMs:Null<Float>, clock:Null<GameClock>)
    {
        this.id = id;
        this.opponentNickname = opponentNickname;
        this.ownColor = ownColor;
        this.timeControl = timeControl;
        this.rated = rated;
        this.startedAtMs = startedAtMs;
        this.position = position;
        this.plyCount = plyCount;
        this.lastPlyAtMs = lastPlyAtMs;
        this.clock = clock;
    }

    public function isTimed():Bool
    {
        return !timeControl.match(None);
    }

    public function isOwnMove():Bool
    {
        return position.turnColor == ownColor;
    }

    /** The number of the move being played, each ply counting as a move, starting from 1 **/
    public function moveNumber():Int
    {
        return plyCount + 1;
    }

    /** Unix time in milliseconds since which the side to move has been thinking **/
    public function waitingSinceMs():Float
    {
        return lastPlyAtMs ?? startedAtMs;
    }

    /** A copy with the state after a move, a rollback or time being added **/
    public function updated(position:Position, plyCount:Int, lastPlyAtMs:Null<Float>, clock:Null<GameClock>):OngoingGame
    {
        return new OngoingGame(id, opponentNickname, ownColor, timeControl, rated, startedAtMs, position, plyCount, lastPlyAtMs, clock);
    }
}
