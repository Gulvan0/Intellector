package client.ui.common.board.annotations;

/** Where annotations are drawn (`AnnotationLayer`), knowing no annotation rules **/
interface AnnotationCanvas
{
    /** Draws exactly `rings` and `arrows` (plus the preview arrow, if any) **/
    public function setAnnotations(rings:Array<HexAnnotation>, arrows:Array<ArrowAnnotation>):Void;

    /** Shows `arrow` on top of the annotations, or removes the preview if `null` **/
    public function setPreviewArrow(arrow:Null<ArrowAnnotation>):Void;
}
