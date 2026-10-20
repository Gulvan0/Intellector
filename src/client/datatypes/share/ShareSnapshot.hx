package client.datatypes.share;

import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;

/** What the share overlay shares, taken when it opens **/
typedef ShareSnapshot = {
    /** The position shown on the board **/
    position:Position,
    /** The colour at the bottom of the board **/
    orientation:PieceColor,
    /** The ply that led to `position`, if any **/
    lastMove:Null<RawPly>,
    /** The game being played or watched; null outside a game page **/
    game:Null<SharedGame>
}
