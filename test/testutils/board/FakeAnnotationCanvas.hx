package testutils.board;

import client.ui.common.board.annotations.AnnotationCanvas;
import client.ui.common.board.annotations.ArrowAnnotation;
import client.ui.common.board.annotations.HexAnnotation;

class FakeAnnotationCanvas implements AnnotationCanvas
{
    public var rings(default, null):Array<HexAnnotation> = [];
    public var arrows(default, null):Array<ArrowAnnotation> = [];
    public var previewArrow(default, null):Null<ArrowAnnotation> = null;

    /** How many times the preview arrow was set **/
    public var previewUpdates(default, null):Int = 0;

    public function new() {}

    public function setAnnotations(rings:Array<HexAnnotation>, arrows:Array<ArrowAnnotation>):Void
    {
        this.rings = rings;
        this.arrows = arrows;
    }

    public function setPreviewArrow(arrow:Null<ArrowAnnotation>):Void
    {
        previewArrow = arrow;
        previewUpdates++;
    }
}
