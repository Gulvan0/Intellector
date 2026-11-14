package client.datatypes.games;

import client.datatypes.game.GameParticipant;
import client.datatypes.game.Outcome;
import client.datatypes.timecontrol.TimeControlKind;

/** A game as the game database's result table shows it **/
class ArchiveGame
{
    public final id:Int;
    public final white:GameParticipant;
    public final black:GameParticipant;
    /** Unix time, in milliseconds; null when not recorded **/
    public final startedAtMs:Null<Float>;
    /** Null while the game goes on, or when not recorded **/
    public final endedAtMs:Null<Float>;
    /** Elapsed as of the search for an ongoing game; null when a timestamp isn't recorded **/
    public final durationMs:Null<Float>;
    public final timeControlKind:TimeControlKind;
    /** Null for correspondence **/
    public final startSeconds:Null<Int>;
    /** Null for correspondence **/
    public final incrementSeconds:Null<Int>;
    public final rated:Bool;
    /** Null for the default starting position **/
    public final customStartingSip:Null<String>;
    public final openingId:Null<Int>;
    /** Null while the game goes on **/
    public final outcome:Null<Outcome>;
    public final moveCount:Int;
    /** Null when not recorded **/
    public final whiteTimeLeftMs:Null<Float>;
    /** Null when not recorded **/
    public final blackTimeLeftMs:Null<Float>;

    public function new(id:Int, white:GameParticipant, black:GameParticipant, startedAtMs:Null<Float>, endedAtMs:Null<Float>, durationMs:Null<Float>, timeControlKind:TimeControlKind, startSeconds:Null<Int>, incrementSeconds:Null<Int>, rated:Bool, customStartingSip:Null<String>, openingId:Null<Int>, outcome:Null<Outcome>, moveCount:Int, whiteTimeLeftMs:Null<Float>, blackTimeLeftMs:Null<Float>)
    {
        this.id = id;
        this.white = white;
        this.black = black;
        this.startedAtMs = startedAtMs;
        this.endedAtMs = endedAtMs;
        this.durationMs = durationMs;
        this.timeControlKind = timeControlKind;
        this.startSeconds = startSeconds;
        this.incrementSeconds = incrementSeconds;
        this.rated = rated;
        this.customStartingSip = customStartingSip;
        this.openingId = openingId;
        this.outcome = outcome;
        this.moveCount = moveCount;
        this.whiteTimeLeftMs = whiteTimeLeftMs;
        this.blackTimeLeftMs = blackTimeLeftMs;
    }
}
