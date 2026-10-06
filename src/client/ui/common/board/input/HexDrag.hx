package client.ui.common.board.input;

import client.ui.common.board.BoardPoint;
import intellectorboard.primitives.hex.HexCoords;

/** The pointer moved with a button held: over `hex` (`null` off the board), at `point` **/
typedef HexDrag =
{
    hex:Null<HexCoords>,
    point:BoardPoint,
    modifiers:Modifiers
}
