package client.ui.common.board.tools;

import intellectorboard.primitives.piece.PieceKind;

/**
    What still has to be chosen before a piece's move from one hex to another is complete.
**/
enum CompletionKind
{
    // Nothing: the move is complete as is.
    None;
    // A Progressor promotes: which piece it becomes.
    Promotion;
    // The capturing piece may morph into `capturedKind`: whether it does.
    Chameleon(capturedKind:PieceKind);
    // A premove that may turn out to be a chameleon capture: which kind to morph into, if asked.
    PremoveChameleon;
}
