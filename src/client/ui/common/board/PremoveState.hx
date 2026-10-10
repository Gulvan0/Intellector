package client.ui.common.board;

import intellectorboard.primitives.piece.PieceColor;

/** What a live game's move policy needs to know of the premove queue (`Premoves`) **/
interface PremoveState
{
    /** Whose turn it is in the real position, not the premove-advanced one **/
    public function realTurn():PieceColor;

    public function isEnabled():Bool;

    public function hasQueued():Bool;
}
