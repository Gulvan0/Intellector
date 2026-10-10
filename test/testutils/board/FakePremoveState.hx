package testutils.board;

import client.ui.common.board.PremoveState;
import intellectorboard.primitives.piece.PieceColor;

class FakePremoveState implements PremoveState
{
    public var turn:PieceColor;
    public var enabled:Bool;
    public var queued:Bool = false;

    public function new(turn:PieceColor, enabled:Bool)
    {
        this.turn = turn;
        this.enabled = enabled;
    }

    public function realTurn():PieceColor
    {
        return turn;
    }

    public function isEnabled():Bool
    {
        return enabled;
    }

    public function hasQueued():Bool
    {
        return queued;
    }
}
