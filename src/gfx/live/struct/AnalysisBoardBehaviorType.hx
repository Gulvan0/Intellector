package gfx.live.struct;

import net.shared.PieceColor;
import net.shared.PieceType;

enum AnalysisBoardBehaviorType
{
    Playthrough;
    EditorMove;
    EditorDelete;
    EditorSet(piece:PieceType, color:PieceColor);
}