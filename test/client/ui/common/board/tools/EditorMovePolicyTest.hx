package client.ui.common.board.tools;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import utest.Assert;
import utest.Test;

class EditorMovePolicyTest extends Test
{
    private final policy:EditorMovePolicy = new EditorMovePolicy();

    private function testMovesFreely():Void
    {
        Assert.equals(PieceMoveMode.FreeMove, policy.pickMode(Position.defaultStarting()));
    }

    private function testAnyPieceOfEitherColorCanBePickedUp():Void
    {
        var position:Position = Position.defaultStarting();

        Assert.isTrue(policy.canPickUp(position, FreeMove, new HexCoords(4, 5)));
        Assert.isTrue(policy.canPickUp(position, FreeMove, new HexCoords(4, 0)));
        Assert.isFalse(policy.canPickUp(position, FreeMove, new HexCoords(4, 3)));
    }

    private function testAnyHexIsADestinationAndNeedsNothing():Void
    {
        var position:Position = Position.defaultStarting();

        Assert.isNull(policy.destinations(position, FreeMove, new HexCoords(4, 6)));
        Assert.same(CompletionKind.None, policy.completion(position, FreeMove, new HexCoords(4, 5), new HexCoords(4, 0)));
    }

    private function testShowsNoMarkersAndDropsChoiceOnMove():Void
    {
        Assert.isFalse(policy.showsMarkers(FreeMove));
        Assert.isFalse(policy.keepsChoiceAcrossMove(Position.defaultStarting()));
    }
}
