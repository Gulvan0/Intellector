package client.ui.common.board.annotations;

import client.ui.common.board.AnnotationColor;
import intellectorboard.primitives.hex.HexCoords;

/** An arrow drawn by the user from one hex to another **/
typedef ArrowAnnotation =
{
    from:HexCoords,
    to:HexCoords,
    color:AnnotationColor
}
