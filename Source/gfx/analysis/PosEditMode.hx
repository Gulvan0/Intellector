package gfx.analysis;

import struct.PieceType;
import struct.PieceColor;

enum PosEditMode 
{
    Move;
    Delete;
    Set(type:PieceType, color:PieceColor);
}