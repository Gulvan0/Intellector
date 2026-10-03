package client.ui.common.board.input;

import client.ui.common.board.BoardPoint;
import intellectorboard.primitives.hex.HexCoords;

/**
    The pointer moved while a button is held. `hex` is the hex under it (`null` off the board),
    `point` its exact position on the board, wherever it is.
**/
typedef HexDrag =
{
    hex:Null<HexCoords>,
    point:BoardPoint,
    modifiers:Modifiers
}
