package client.datatypes.variations;

import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;
import testutils.Positions;
import utest.Assert;
import utest.Test;

class PositionDraftTest extends Test
{
    private function testStartsUnchanged():Void
    {
        var draft:PositionDraft = new PositionDraft(Position.defaultStarting());

        Assert.isFalse(draft.isChanged());
        Assert.isTrue(draft.isStarting());
        Assert.isTrue(draft.isValid());
        Assert.notEquals(draft.original, draft.position);
    }

    private function testEditsReplaceThePosition():Void
    {
        var draft:PositionDraft = new PositionDraft(Position.defaultStarting());
        var before:Position = draft.position;
        var hex:HexCoords = new HexCoords(4, 3);

        draft.placePiece(hex, new PieceData(Aggressor, White));

        Assert.notEquals(before, draft.position);
        Assert.isTrue(before.get(hex).isEmpty());
        Assert.equals(Aggressor, draft.position.getPiece(hex).type);
        Assert.isTrue(draft.isChanged());
        Assert.isFalse(draft.isStarting());
    }

    private function testMovePiece():Void
    {
        var original:Position = Positions.make(White, [{i: 0, j: 0, kind: Dominator, color: Black}]);
        var draft:PositionDraft = new PositionDraft(original);

        draft.movePiece(new HexCoords(0, 0), new HexCoords(3, 3));

        Assert.isTrue(draft.position.get(new HexCoords(0, 0)).isEmpty());
        Assert.equals(Dominator, draft.position.getPiece(new HexCoords(3, 3)).type);
    }

    private function testMovingAPieceOntoItselfKeepsIt():Void
    {
        var original:Position = Positions.make(White, [{i: 0, j: 0, kind: Dominator, color: Black}]);
        var draft:PositionDraft = new PositionDraft(original);

        draft.movePiece(new HexCoords(0, 0), new HexCoords(0, 0));

        Assert.equals(Dominator, draft.position.getPiece(new HexCoords(0, 0)).type);
        Assert.isFalse(draft.isChanged());
    }

    private function testClearHex():Void
    {
        var original:Position = Positions.make(White, [{i: 0, j: 0, kind: Dominator, color: Black}]);
        var draft:PositionDraft = new PositionDraft(original);

        draft.clearHex(new HexCoords(0, 0));

        Assert.isTrue(draft.isClear());
    }

    private function testTurnColourAloneCountsAsAChange():Void
    {
        var draft:PositionDraft = new PositionDraft(Position.defaultStarting());

        draft.setTurnColor(Black);

        Assert.isTrue(draft.isChanged());
        Assert.isFalse(draft.isStarting());
        draft.setTurnColor(White);
        Assert.isFalse(draft.isChanged());
    }

    private function testClearKeepsTheSideToMove():Void
    {
        var draft:PositionDraft = new PositionDraft(Position.defaultStarting());
        draft.setTurnColor(Black);

        draft.clear();

        Assert.isTrue(draft.isClear());
        Assert.equals(Black, draft.position.turnColor);
        Assert.isFalse(draft.isValid());
    }

    private function testResetAndStarting():Void
    {
        var original:Position = Positions.make(Black, [
            {i: 4, j: 0, kind: Intellector, color: Black},
            {i: 4, j: 6, kind: Intellector, color: White}
        ]);
        var draft:PositionDraft = new PositionDraft(original);

        draft.setStarting();
        Assert.isTrue(draft.isStarting());
        Assert.isTrue(draft.isChanged());

        draft.reset();
        Assert.isFalse(draft.isChanged());
        Assert.equals(Black, draft.position.turnColor);
    }

    private function testValidity():Void
    {
        var oneIntellectorEach:Position = Positions.make(White, [
            {i: 4, j: 2, kind: Intellector, color: Black},
            {i: 4, j: 4, kind: Intellector, color: White}
        ]);
        Assert.isTrue(new PositionDraft(oneIntellectorEach).isValid());

        var draft:PositionDraft = new PositionDraft(oneIntellectorEach);
        draft.placePiece(new HexCoords(2, 4), new PieceData(Intellector, White));
        Assert.isFalse(draft.isValid());

        var missingBlack:PositionDraft = new PositionDraft(oneIntellectorEach);
        missingBlack.clearHex(new HexCoords(4, 2));
        Assert.isFalse(missingBlack.isValid());
    }
}
