package net.shared.board;

import net.shared.board.Direction;
import net.shared.PieceType;

enum MovementPattern
{
    SimpleJump(distance:Int);
    NonCapturingJump(distance:Int);
    NormalSlide;
    Swap(partner:PieceType);
}