package client.ui.common.board;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;
import morestd.Signal;
import testutils.Hexes.hex;
import testutils.Positions;
import testutils.board.FakeBoardView;
import testutils.board.FakeHexFills;
import utest.Assert;
import utest.Test;

class PremovesTest extends Test
{
    private var board:FakeBoardView;
    private var fills:FakeHexFills;
    private var playMove:Signal<RawPly>;
    private var played:Array<RawPly>;
    private var intents:Signal<PremoveIntent>;
    private var premoves:Premoves;

    // the real position, as the page tracks it
    private var realPosition:Position;

    private function setup():Void
    {
        realPosition = Position.defaultStarting().copy(Black);
        board = new FakeBoardView(realPosition);
        fills = new FakeHexFills();
        playMove = new Signal();
        played = [];
        playMove.subscribe(played.push);
        intents = new Signal();
        premoves = new Premoves(board, new HexTints(fills, FakeHexFills.PALETTE), MoveRulesAdapter.DEFAULT, White, realPosition, true, playMove, intents);
    }

    private static function ply(fromI:Int, fromJ:Int, toI:Int, toJ:Int, ?morphInto:PieceKind):RawPly
    {
        return RawPly.construct(hex(fromI, fromJ), hex(toI, toJ), morphInto);
    }

    // `position` after `ply`, the turn passed
    private static function after(position:Position, ply:RawPly):Position
    {
        var result:Position = position.copy(position.turnColor.opposite());
        var piece:PieceData = result.getPiece(ply.from);
        result.set(ply.from, Empty);
        result.set(ply.to, Occupied(new PieceData(ply.morphInto ?? piece.type, piece.color)));
        return result;
    }

    /** The page's handler: plays the move and reports the resulting position back **/
    private function playMovesLikeThePage():Void
    {
        playMove.subscribe(move -> {
            realPosition = after(realPosition, move);
            premoves.setRealPosition(realPosition, Move);
        });
    }

    private function opponentPlays(move:RawPly):Void
    {
        realPosition = after(realPosition, move);
        premoves.setRealPosition(realPosition, Move);
    }

    private function assertShown(kind:Null<PieceKind>, coords:HexCoords, ?pos:haxe.PosInfos):Void
    {
        Assert.equals(kind, board.getPosition().getPiece(coords)?.type, pos);
    }

    private function testQueuedPremoveIsShownPlayedAndTinted():Void
    {
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));

        Assert.isTrue(premoves.hasQueued());
        assertShown(Progressor, hex(4, 4));
        assertShown(null, hex(4, 5));
        Assert.same([PositionChangeCause.PremovesChanged], board.causes);
        Assert.equals("premove", fills.entryAt(hex(4, 5)));
        Assert.equals("premove", fills.entryAt(hex(4, 4)));
    }

    private function testRealTurnIgnoresQueuedPremoves():Void
    {
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));

        Assert.equals(PieceColor.Black, premoves.realTurn());
    }

    private function testDisabledQueueIgnoresPremoves():Void
    {
        premoves.setEnabled(false);
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));

        Assert.isFalse(premoves.hasQueued());
        Assert.isFalse(premoves.isEnabled());
        Assert.same([], board.causes);
    }

    private function testDisablingDropsQueue():Void
    {
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));
        premoves.setEnabled(false);

        Assert.isFalse(premoves.hasQueued());
        assertShown(Progressor, hex(4, 5));
        Assert.same([], fills.filledScalars());
    }

    private function testCancelAllShowsRealPosition():Void
    {
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));
        intents.dispatch(CancelAll);

        Assert.isFalse(premoves.hasQueued());
        Assert.equals(realPosition, board.getPosition());
        Assert.same([], fills.filledScalars());
    }

    private function testCancellingEmptyQueueShowsNothingNew():Void
    {
        intents.dispatch(CancelAll);

        Assert.same([], board.causes);
    }

    private function testOpponentMoveFiresFirstPremove():Void
    {
        playMovesLikeThePage();
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));
        intents.dispatch(Queue(ply(4, 4, 4, 3), null));

        opponentPlays(ply(4, 1, 4, 2));

        Assert.equals(1, played.length);
        Assert.isTrue(played[0].from.equals(hex(4, 5)));
        Assert.equals(PieceColor.Black, premoves.realTurn());
        assertShown(Progressor, hex(4, 3));
        Assert.same(Positions.sortedScalars([hex(4, 4), hex(4, 3)]), fills.filledScalars());
    }

    private function testFiredPremoveShowsTheResultOnce():Void
    {
        playMovesLikeThePage();
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));
        board.causes.resize(0);

        opponentPlays(ply(4, 1, 4, 2));

        Assert.same([PositionChangeCause.Move], board.causes);
        Assert.equals(realPosition, board.getPosition());
    }

    private function testFailingPremoveDropsQueueAndShowsRealPosition():Void
    {
        intents.dispatch(Queue(ply(4, 5, 4, 3), null));
        intents.dispatch(Queue(ply(2, 5, 2, 4), null));

        opponentPlays(ply(4, 1, 4, 2));

        Assert.same([], played);
        Assert.isFalse(premoves.hasQueued());
        Assert.equals(realPosition, board.getPosition());
    }

    private function testOwnMoveDoesNotFirePremoves():Void
    {
        premoves.setRealPosition(Position.defaultStarting(), Replacement);
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));

        // the turn passes to Black: premoves wait
        realPosition = after(Position.defaultStarting(), ply(2, 5, 2, 4));
        premoves.setRealPosition(realPosition, Move);

        Assert.same([], played);
        Assert.isTrue(premoves.hasQueued());
        assertShown(Progressor, hex(4, 4));
    }

    private function testReplacementDropsQueue():Void
    {
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));
        premoves.setRealPosition(Position.defaultStarting(), Replacement);

        Assert.same([], played);
        Assert.isFalse(premoves.hasQueued());
        Assert.equals(PositionChangeCause.Replacement, board.causes[board.causes.length - 1]);
    }

    private function testDisposeStopsQueuing():Void
    {
        intents.dispatch(Queue(ply(4, 5, 4, 4), null));
        premoves.dispose();

        Assert.isFalse(premoves.hasQueued());
        assertShown(Progressor, hex(4, 5));

        intents.dispatch(Queue(ply(2, 5, 2, 4), null));

        Assert.isFalse(premoves.hasQueued());
    }
}
