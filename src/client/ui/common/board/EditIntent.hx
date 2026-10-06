package client.ui.common.board;

import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;

/** What the user asked of the position being edited (consumed by a position editor) **/
enum EditIntent
{
    MovePiece(from:HexCoords, to:HexCoords);
    PlacePiece(hex:HexCoords, piece:PieceData);
    ClearHex(hex:HexCoords);
}
