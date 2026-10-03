package client.ui.common.board.annotations;

import client.ui.common.board.AnnotationColor;
import intellectorboard.primitives.hex.HexCoords;

/**
    What the user asked of the annotations (consumed by `BoardAnnotations`, or by a page that owns
    the annotations itself).
**/
enum AnnotationIntent
{
    AnnotateHex(hex:HexCoords, color:AnnotationColor);
    AnnotateArrow(from:HexCoords, to:HexCoords, color:AnnotationColor);
    ClearAnnotations;
}
