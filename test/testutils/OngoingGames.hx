package testutils;

import client.datatypes.FischerTimeControl;
import client.datatypes.GameClock;
import client.datatypes.OngoingGame;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

class OngoingGames
{
    /** A timed game of the user's, playing White, `ownMs`/`opponentMs` left as of time 0, the side to move's clock running **/
    public static function timed(id:Int, ownMove:Bool, ownMs:Int, opponentMs:Int):OngoingGame
    {
        var turnColor:PieceColor = ownMove ? White : Black;
        var clock:GameClock = new GameClock(ownMs, opponentMs, turnColor, 0);
        return new OngoingGame(id, 'Opponent $id', White, Fischer(new FischerTimeControl(600, 5)), true, 0, Position.empty().copy(turnColor), 2, 0, clock);
    }

    /** A correspondence game of the user's, playing White, its last move made at `lastPlyAtMs` **/
    public static function correspondence(id:Int, ownMove:Bool, lastPlyAtMs:Null<Float>, startedAtMs:Float = 0):OngoingGame
    {
        var turnColor:PieceColor = ownMove ? White : Black;
        return new OngoingGame(id, 'Opponent $id', White, None, false, startedAtMs, Position.empty().copy(turnColor), 2, lastPlyAtMs, null);
    }

    public static function ids(games:Array<OngoingGame>):Array<Int>
    {
        return games.map(game -> game.id);
    }
}
