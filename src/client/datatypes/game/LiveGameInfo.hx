package client.datatypes.game;

import client.datatypes.timecontrol.TimeControl;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

/** What doesn't change during a game **/
class LiveGameInfo
{
    public final id:Int;
    public final white:GameParticipant;
    public final black:GameParticipant;
    public final timeControl:TimeControl;
    public final rated:Bool;
    /** Unix time, in milliseconds **/
    public final startedAtMs:Float;
    public final startingPosition:Position;
    public final customStartingPosition:Bool;
    /** Uploaded by an external client rather than played on the site **/
    public final external:Bool;

    public function new(id:Int, white:GameParticipant, black:GameParticipant, timeControl:TimeControl, rated:Bool, startedAtMs:Float, startingPosition:Position, customStartingPosition:Bool, external:Bool)
    {
        this.id = id;
        this.white = white;
        this.black = black;
        this.timeControl = timeControl;
        this.rated = rated;
        this.startedAtMs = startedAtMs;
        this.startingPosition = startingPosition;
        this.customStartingPosition = customStartingPosition;
        this.external = external;
    }

    public function participant(color:PieceColor):GameParticipant
    {
        return color == White ? white : black;
    }

    /** The colour `userRef` plays, or null if they don't **/
    public function colorOf(userRef:Null<String>):Null<PieceColor>
    {
        if (userRef == null)
            return null;
        if (white.ref == userRef)
            return White;
        if (black.ref == userRef)
            return Black;
        return null;
    }

    public function isTimed():Bool
    {
        return !timeControl.match(None);
    }

    /** Both players' clocks before the first move, null for a correspondence game **/
    public function initialClock():Null<GameClock>
    {
        return switch timeControl {
            case None: null;
            case Fischer(instance): new GameClock(instance.startSeconds * 1000, instance.startSeconds * 1000, null, startedAtMs);
        }
    }
}
