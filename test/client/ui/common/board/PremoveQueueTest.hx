package client.ui.common.board;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;
import testutils.Positions;
import utest.Assert;
import utest.Test;

class PremoveQueueTest extends Test
{
    private static final RULES:MoveRules = MoveRulesAdapter.DEFAULT;

    private var queue:PremoveQueue;

    private function setup():Void
    {
        queue = new PremoveQueue();
    }

    private static function ply(fromI:Int, fromJ:Int, toI:Int, toJ:Int, ?morphInto:PieceKind):RawPly
    {
        return RawPly.construct(new HexCoords(fromI, fromJ), new HexCoords(toI, toJ), morphInto);
    }

    // a White Dominator on (4, 5) that can capture a Black Aggressor on (4, 2), its Intellector adjacent or not
    private static function capturePosition(withAura:Bool):Position
    {
        return Positions.make(White, [
            {i: withAura ? 4 : 0, j: 6, kind: Intellector, color: White},
            {i: 4, j: 5, kind: Dominator, color: White},
            {i: 4, j: 2, kind: Aggressor, color: Black},
            {i: 8, j: 0, kind: Intellector, color: Black}
        ]);
    }

    // a White Progressor on (4, 1), a step from promoting
    private static function promotionPosition():Position
    {
        return Positions.make(White, [
            {i: 0, j: 6, kind: Intellector, color: White},
            {i: 4, j: 1, kind: Progressor, color: White},
            {i: 8, j: 0, kind: Intellector, color: Black}
        ]);
    }

    private function assertPiece(kind:Null<PieceKind>, color:Null<PieceColor>, position:Position, i:Int, j:Int, ?pos:haxe.PosInfos):Void
    {
        var piece:Null<PieceData> = position.getPiece(new HexCoords(i, j));
        Assert.equals(kind, piece?.type, pos);
        Assert.equals(color, piece?.color, pos);
    }

    private function assertPly(expected:RawPly, actual:Null<RawPly>, ?pos:haxe.PosInfos):Void
    {
        if (actual == null)
        {
            Assert.fail('expected a ply, got null', pos);
            return;
        }

        Assert.isTrue(expected.from.equals(actual.from), pos);
        Assert.isTrue(expected.to.equals(actual.to), pos);
        Assert.equals(expected.morphInto, actual.morphInto, pos);
    }

    private function testNewQueueIsEmpty():Void
    {
        var position:Position = Position.defaultStarting();

        Assert.isTrue(queue.isEmpty());
        Assert.same([], queue.hexes());
        Assert.equals(position, queue.applyTo(position));
        Assert.isNull(queue.takeNext(position, White, RULES));
    }

    private function testHexesListDeparturesAndDestinationsInPlayOrder():Void
    {
        queue.add(ply(4, 5, 4, 4), null);
        queue.add(ply(2, 5, 2, 4), null);

        Assert.isFalse(queue.isEmpty());
        Assert.same(
            Positions.scalars([new HexCoords(4, 5), new HexCoords(4, 4), new HexCoords(2, 5), new HexCoords(2, 4)]),
            Positions.scalars(queue.hexes())
        );
    }

    private function testClearEmptiesQueue():Void
    {
        queue.add(ply(4, 5, 4, 4), null);
        queue.clear();

        Assert.isTrue(queue.isEmpty());
        Assert.same([], queue.hexes());
    }

    private function testApplyToPlaysPremovesInOrderOnACopy():Void
    {
        var position:Position = Position.defaultStarting();
        queue.add(ply(4, 5, 4, 4), null);
        queue.add(ply(4, 4, 4, 3), null);

        var result:Position = queue.applyTo(position);

        Assert.notEquals(position, result);
        assertPiece(null, null, result, 4, 5);
        assertPiece(null, null, result, 4, 4);
        assertPiece(Progressor, White, result, 4, 3);
        Assert.equals(White, result.turnColor);

        assertPiece(Progressor, White, position, 4, 5);
        assertPiece(null, null, position, 4, 3);
    }

    private function testApplyToReplacesCapturedPiece():Void
    {
        queue.add(ply(4, 5, 4, 2), null);

        assertPiece(Dominator, White, queue.applyTo(capturePosition(true)), 4, 2);
    }

    private function testApplyToShowsPromotionChoice():Void
    {
        queue.add(ply(4, 1, 4, 0, Aggressor), null);

        assertPiece(Aggressor, White, queue.applyTo(promotionPosition()), 4, 0);
    }

    private function testApplyToShowsChameleonChoice():Void
    {
        queue.add(ply(4, 5, 4, 2), Aggressor);

        assertPiece(Aggressor, White, queue.applyTo(capturePosition(true)), 4, 2);
    }

    private function testApplyToSkipsPremoveFromEmptiedHex():Void
    {
        queue.add(ply(3, 3, 3, 2), null);
        queue.add(ply(4, 5, 4, 4), null);

        var result:Position = queue.applyTo(Position.defaultStarting());

        assertPiece(null, null, result, 3, 2);
        assertPiece(Progressor, White, result, 4, 4);
    }

    private function testTakeNextReturnsLegalPremoveAndKeepsTheRest():Void
    {
        queue.add(ply(4, 5, 4, 4), null);
        queue.add(ply(2, 5, 2, 4), null);

        assertPly(ply(4, 5, 4, 4), queue.takeNext(Position.defaultStarting(), White, RULES));
        Assert.same(Positions.scalars([new HexCoords(2, 5), new HexCoords(2, 4)]), Positions.scalars(queue.hexes()));
    }

    private function testIllegalPremoveDropsWholeQueue():Void
    {
        queue.add(ply(4, 5, 4, 3), null);
        queue.add(ply(2, 5, 2, 4), null);

        Assert.isNull(queue.takeNext(Position.defaultStarting(), White, RULES));
        Assert.isTrue(queue.isEmpty());
    }

    private function testPremoveOfEmptiedHexDropsQueue():Void
    {
        queue.add(ply(3, 3, 3, 2), null);

        Assert.isNull(queue.takeNext(Position.defaultStarting(), White, RULES));
        Assert.isTrue(queue.isEmpty());
    }

    private function testPremoveOfOpponentPieceDropsQueue():Void
    {
        queue.add(ply(4, 1, 4, 2), null);

        Assert.isNull(queue.takeNext(Position.defaultStarting(), White, RULES));
        Assert.isTrue(queue.isEmpty());
    }

    private function testPromotionPremoveKeepsItsChoice():Void
    {
        queue.add(ply(4, 1, 4, 0, Dominator), null);

        assertPly(ply(4, 1, 4, 0, Dominator), queue.takeNext(promotionPosition(), White, RULES));
    }

    private function testPromotionPremoveWithoutChoiceIsDropped():Void
    {
        queue.add(ply(4, 1, 4, 0), null);

        Assert.isNull(queue.takeNext(promotionPosition(), White, RULES));
        Assert.isTrue(queue.isEmpty());
    }

    private function testUnaskedChameleonPlaysWithoutMorphing():Void
    {
        queue.add(ply(4, 5, 4, 2), null);

        assertPly(ply(4, 5, 4, 2), queue.takeNext(capturePosition(true), White, RULES));
    }

    private function testDeclinedChameleonPlaysWithoutMorphing():Void
    {
        queue.add(ply(4, 5, 4, 2), Dominator);

        assertPly(ply(4, 5, 4, 2), queue.takeNext(capturePosition(true), White, RULES));
    }

    private function testChosenChameleonMorphsWhenPossible():Void
    {
        queue.add(ply(4, 5, 4, 2), Aggressor);

        assertPly(ply(4, 5, 4, 2, Aggressor), queue.takeNext(capturePosition(true), White, RULES));
    }

    private function testChosenChameleonOfAnotherKindIsDropped():Void
    {
        queue.add(ply(4, 5, 4, 2), Liberator);

        Assert.isNull(queue.takeNext(capturePosition(true), White, RULES));
        Assert.isTrue(queue.isEmpty());
    }

    private function testChosenChameleonWithoutCaptureIsDropped():Void
    {
        queue.add(ply(4, 5, 4, 3), Aggressor);

        Assert.isNull(queue.takeNext(capturePosition(true), White, RULES));
    }

    private function testChosenChameleonWithoutAuraIsDropped():Void
    {
        queue.add(ply(4, 5, 4, 2), Aggressor);

        Assert.isNull(queue.takeNext(capturePosition(false), White, RULES));
    }
}
