package client.ui.common.board.tools;

import client.ui.common.board.MoveRulesAdapter;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceKind;
import testutils.Positions;
import utest.Assert;
import utest.Test;

class MoveCompletionTest extends Test
{
    // a White Dominator on (4, 5) facing `target` on (4, 2), its Intellector adjacent or not
    private static function capturePosition(target:PieceKind, withAura:Bool):Position
    {
        return Positions.make(White, [
            {i: withAura ? 4 : 0, j: 6, kind: Intellector, color: White},
            {i: 4, j: 5, kind: Dominator, color: White},
            {i: 4, j: 2, kind: target, color: Black},
            {i: target == Intellector ? 2 : 8, j: 0, kind: Intellector, color: Black}
        ]);
    }

    private function assertCompletion(expected:CompletionKind, position:Position, fromI:Int, fromJ:Int, toI:Int, toJ:Int, ?pos:haxe.PosInfos):Void
    {
        var actual:CompletionKind = MoveCompletion.ofMove(MoveRulesAdapter.DEFAULT, position, new HexCoords(fromI, fromJ), new HexCoords(toI, toJ));
        Assert.same(expected, actual, pos);
    }

    private function testPlainMoveNeedsNothing():Void
    {
        assertCompletion(None, Position.defaultStarting(), 4, 5, 4, 4);
    }

    private function testProgressorReachingLastRankPromotes():Void
    {
        var position:Position = Positions.make(White, [
            {i: 0, j: 6, kind: Intellector, color: White},
            {i: 4, j: 1, kind: Progressor, color: White},
            {i: 8, j: 0, kind: Intellector, color: Black}
        ]);

        assertCompletion(Promotion, position, 4, 1, 4, 0);
    }

    private function testCaptureNearOwnIntellectorOffersChameleon():Void
    {
        assertCompletion(Chameleon(Aggressor), capturePosition(Aggressor, true), 4, 5, 4, 2);
    }

    private function testCaptureWithoutAuraNeedsNothing():Void
    {
        assertCompletion(None, capturePosition(Aggressor, false), 4, 5, 4, 2);
    }

    private function testCapturingSameKindNeedsNothing():Void
    {
        assertCompletion(None, capturePosition(Dominator, true), 4, 5, 4, 2);
    }

    private function testCapturingIntellectorNeedsNothing():Void
    {
        assertCompletion(None, capturePosition(Intellector, true), 4, 5, 4, 2);
    }

    private function testNonCaptureNearOwnIntellectorNeedsNothing():Void
    {
        assertCompletion(None, capturePosition(Aggressor, true), 4, 5, 4, 3);
    }
}
