package client.ui.common.board.tools;

import client.ui.common.board.MoveRulesAdapter;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import testutils.Positions;
import utest.Assert;
import utest.Test;

class AnalysisMovePolicyTest extends Test
{
    private final policy:AnalysisMovePolicy = new AnalysisMovePolicy(MoveRulesAdapter.DEFAULT);

    private function testAlwaysMoves():Void
    {
        Assert.equals(PieceMoveMode.Move, policy.pickMode(Position.defaultStarting()));
        Assert.equals(PieceMoveMode.Move, policy.pickMode(Position.defaultStarting().copy(Black)));
    }

    private function testOnlySideToMoveCanPickUp():Void
    {
        var whiteToMove:Position = Position.defaultStarting();
        var blackToMove:Position = whiteToMove.copy(Black);
        var whitePiece:HexCoords = new HexCoords(4, 5);
        var blackPiece:HexCoords = new HexCoords(4, 1);

        Assert.isTrue(policy.canPickUp(whiteToMove, Move, whitePiece));
        Assert.isFalse(policy.canPickUp(whiteToMove, Move, blackPiece));
        Assert.isTrue(policy.canPickUp(blackToMove, Move, blackPiece));
        Assert.isFalse(policy.canPickUp(blackToMove, Move, whitePiece));
    }

    private function testEmptyHexCannotBePickedUp():Void
    {
        Assert.isFalse(policy.canPickUp(Position.defaultStarting(), Move, new HexCoords(4, 3)));
    }

    private function testDestinationsAreLegalMoves():Void
    {
        var position:Position = Position.defaultStarting();
        var from:HexCoords = new HexCoords(4, 5);

        Assert.same(
            Positions.scalars(MoveRulesAdapter.DEFAULT.getLegalDestinations(from, position.pieces)),
            Positions.scalars(policy.destinations(position, Move, from))
        );
        Assert.same(
            Positions.sortedScalars([new HexCoords(3, 4), new HexCoords(4, 4), new HexCoords(5, 4)]),
            Positions.sortedScalars(policy.destinations(position, Move, from))
        );
    }

    private function testCompletionFollowsTheRules():Void
    {
        var position:Position = Positions.make(White, [
            {i: 0, j: 6, kind: Intellector, color: White},
            {i: 4, j: 1, kind: Progressor, color: White},
            {i: 8, j: 0, kind: Intellector, color: Black}
        ]);

        Assert.same(CompletionKind.Promotion, policy.completion(position, Move, new HexCoords(4, 1), new HexCoords(4, 0)));
    }

    private function testShowsMarkersAndDropsChoiceOnMove():Void
    {
        Assert.isTrue(policy.showsMarkers(Move));
        Assert.isFalse(policy.keepsChoiceAcrossMove(Position.defaultStarting()));
    }
}
