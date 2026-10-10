package client.ui.common.board.move_prompt;

import client.ui.common.board.BoardSurface;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;

/** `MovePrompt`s popping over `board` **/
class BoardMovePrompts implements MovePrompts
{
    private final board:BoardSurface;

    public function new(board:BoardSurface)
    {
        this.board = board;
    }

    public function promotion(anchor:HexCoords, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):OpenPrompt
    {
        return MovePrompt.promotion(board, anchor, color, onChosen, onCancelled);
    }

    public function captureMorph(anchor:HexCoords, capturingKind:PieceKind, capturingColor:PieceColor, capturedKind:PieceKind, onDecided:Bool->Void, onCancelled:Void->Void):OpenPrompt
    {
        return MovePrompt.captureMorph(board, anchor, capturingKind, capturingColor, capturedKind, onDecided, onCancelled);
    }

    public function premoveChameleon(anchor:HexCoords, movingKind:PieceKind, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):OpenPrompt
    {
        return MovePrompt.premoveChameleon(board, anchor, movingKind, color, onChosen, onCancelled);
    }
}
