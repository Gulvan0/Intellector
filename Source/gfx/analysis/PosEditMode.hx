package gfx.analysis;

import net.shared.PieceType;
import net.shared.PieceColor;

enum PosEditMode 
{
    Move;
    Delete;
    Set(type:PieceType, color:PieceColor);
}