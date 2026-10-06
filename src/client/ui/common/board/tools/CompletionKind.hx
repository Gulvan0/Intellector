package client.ui.common.board.tools;

import intellectorboard.primitives.piece.PieceKind;

/** What still has to be chosen to complete a move **/
enum CompletionKind
{
    /** Nothing: the move is complete **/
    None;
    /** A Progressor promotes: which piece it becomes **/
    Promotion;
    /** The capturing piece may morph into `capturedKind`: whether it does **/
    Chameleon(capturedKind:PieceKind);
    /** A premove that may become a chameleon capture: which kind to morph into, if asked **/
    PremoveChameleon;
}
