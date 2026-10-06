package client.ui.common.board.annotations;

import client.ui.common.board.AnnotationColor;
import intellectorboard.primitives.hex.HexCoords;

/** A hex marked by the user **/
typedef HexAnnotation =
{
    hex:HexCoords,
    color:AnnotationColor
}
