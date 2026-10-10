package client.ui.common.board.tools;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import utest.Assert;
import utest.Test;

class InertMovePolicyTest extends Test
{
    private final policy:InertMovePolicy = new InertMovePolicy();

    private function testNothingMoves():Void
    {
        var position:Position = Position.defaultStarting();

        Assert.isNull(policy.pickMode(position));
        Assert.isFalse(policy.canPickUp(position, Move, new HexCoords(4, 5)));
        Assert.same([], policy.destinations(position, Move, new HexCoords(4, 5)));
    }
}
