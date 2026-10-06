package client.ui.common.board.input;

import intellectorboard.primitives.hex.HexCoords;

/**
    A button pressed or released over `hex`: `null` is the page background for a press, anywhere
    off the board for a release.
**/
typedef HexPress =
{
    hex:Null<HexCoords>,
    modifiers:Modifiers
}
