package client.ui.common.board.move_prompt;

import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;

/**
    Opens the move choices `PieceMoveTool` can't make (`BoardMovePrompts` on a real board).
    Callbacks are called once the prompt is closed.
**/
interface MovePrompts
{
    /** Which piece a `color` Progressor reaching `anchor` promotes to **/
    public function promotion(anchor:HexCoords, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):OpenPrompt;

    /** Whether `capturingKind` capturing `capturedKind` on `anchor` morphs into it **/
    public function captureMorph(anchor:HexCoords, capturingKind:PieceKind, capturingColor:PieceColor, capturedKind:PieceKind, onDecided:Bool->Void, onCancelled:Void->Void):OpenPrompt;

    /** Which kind a premoved `movingKind` morphs into on capture, its own included **/
    public function premoveChameleon(anchor:HexCoords, movingKind:PieceKind, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):OpenPrompt;
}
