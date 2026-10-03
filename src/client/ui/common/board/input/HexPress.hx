package client.ui.common.board.input;

import intellectorboard.primitives.hex.HexCoords;

/**
    A button pressed or released. `hex` is the hex under the pointer; on a press, `null` means an
    outside press (page background), on a release, anywhere off the board.
**/
typedef HexPress =
{
    hex:Null<HexCoords>,
    modifiers:Modifiers
}
