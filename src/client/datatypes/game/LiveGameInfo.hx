package client.datatypes.game;

import client.datatypes.bot.BotSettings;
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
    public final startedAtMs:Null<Float>;
    public final startingPosition:Position;
    public final customStartingPosition:Bool;
    /** The user ref of whoever uploads the plies of a game played off the site; null for one played on it **/
    public final externalUploaderRef:Null<String>;
    /** The bot an external game is played against, or null **/
    public final bot:Null<BotSettings>;

    public function new(id:Int, white:GameParticipant, black:GameParticipant, timeControl:TimeControl, rated:Bool, startedAtMs:Null<Float>, startingPosition:Position, customStartingPosition:Bool, externalUploaderRef:Null<String>, bot:Null<BotSettings>)
    {
        this.id = id;
        this.white = white;
        this.black = black;
        this.timeControl = timeControl;
        this.rated = rated;
        this.startedAtMs = startedAtMs;
        this.startingPosition = startingPosition;
        this.customStartingPosition = customStartingPosition;
        this.externalUploaderRef = externalUploaderRef;
        this.bot = bot;
    }

    public function isExternal():Bool
    {
        return externalUploaderRef != null;
    }

    /** The colour of the bot an external game is played against, or null **/
    public function botColor():Null<PieceColor>
    {
        if (bot == null)
            return null;
        return white.ref == externalUploaderRef ? Black : White;
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
