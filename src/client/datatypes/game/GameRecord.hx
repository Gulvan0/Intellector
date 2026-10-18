package client.datatypes.game;

import client.datatypes.timecontrol.TimeControl;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

/** A game as listed: its players, settings and latest position, and how it ended if it has **/
class GameRecord
{
    public final id:Int;
    public final white:GameParticipant;
    public final black:GameParticipant;
    public final timeControl:TimeControl;
    public final rated:Bool;
    /** Unix time, in milliseconds; null when not recorded **/
    public final startedAtMs:Null<Float>;
    public final position:Position;
    /** The number of plies made, null when not known (a listed game's summary doesn't tell) **/
    public final plyCount:Null<Int>;
    /** Unix time of the latest move in milliseconds, null before the first one or when not recorded **/
    public final lastPlyAtMs:Null<Float>;
    /** Null while the game goes on **/
    public final ending:Null<GameEnding>;

    public function new(id:Int, white:GameParticipant, black:GameParticipant, timeControl:TimeControl, rated:Bool, startedAtMs:Null<Float>, position:Position, plyCount:Null<Int>, lastPlyAtMs:Null<Float>, ending:Null<GameEnding>)
    {
        this.id = id;
        this.white = white;
        this.black = black;
        this.timeControl = timeControl;
        this.rated = rated;
        this.startedAtMs = startedAtMs;
        this.position = position;
        this.plyCount = plyCount;
        this.lastPlyAtMs = lastPlyAtMs;
        this.ending = ending;
    }

    public function participant(color:PieceColor):GameParticipant
    {
        return color == White ? white : black;
    }

    /** The colour `ref` plays, null if they don't play the game **/
    public function colorOf(ref:String):Null<PieceColor>
    {
        if (white.ref == ref)
            return White;
        if (black.ref == ref)
            return Black;
        return null;
    }

    /** Unix time in milliseconds since which the side to move has been thinking, null when not recorded **/
    public function waitingSinceMs():Null<Float>
    {
        return plyCount != null && plyCount > 0 ? lastPlyAtMs : startedAtMs;
    }

    /** A copy with the state after a move, a rollback or time being added **/
    public function updated(position:Position, plyCount:Int, lastPlyAtMs:Null<Float>):GameRecord
    {
        return new GameRecord(id, white, black, timeControl, rated, startedAtMs, position, plyCount, lastPlyAtMs, ending);
    }
}
