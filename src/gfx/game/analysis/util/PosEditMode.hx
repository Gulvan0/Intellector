package gfx.game.analysis.util;

import net.shared.PieceType;
import net.shared.PieceColor;

enum PosEditMode 
{
    Move;
    Delete;
    Set(type:PieceType, color:PieceColor);
}