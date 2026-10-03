package client.ui.common.board.layers;

import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardPalette;
import client.ui.common.board.BoardPoint;
import client.ui.common.board.BoardProjection;
import client.ui.common.board.annotations.ArrowAnnotation;
import client.ui.common.board.annotations.ArrowGeometry;
import client.ui.common.board.annotations.HexAnnotation;
import haxe.ui.backend.html5.svg.SVGCircleBuilder;
import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxefolio.graphics.SvgLayer;

/**
    Annotation rings and arrows, drawn above the pieces (except a dragged one), every one of them
    translucent. Knows no annotation rules: it draws what it's given - the annotations, and a
    preview arrow (the one being dragged out).
**/
class AnnotationLayer implements BoardLayer
{
    private static inline final OPACITY:String = "0.75";
    // Through the hex's vertices (a hex's circumradius equals its side length).
    private static inline final RING_RADIUS:Float = BoardGeometry.SIDE_LENGTH;
    private static inline final RING_THICKNESS:Float = BoardGeometry.SIDE_LENGTH * 0.24;

    private final layer:SvgLayer;
    private final projection:BoardProjection;
    private var palette:BoardPalette;

    private var rings:Array<HexAnnotation> = [];
    private var arrows:Array<ArrowAnnotation> = [];
    private var previewArrow:Null<ArrowAnnotation> = null;

    public function new(layer:SvgLayer, projection:BoardProjection, palette:BoardPalette)
    {
        this.layer = layer;
        this.projection = projection;
        this.palette = palette;
    }

    /**
        Draws exactly `rings` and `arrows` (plus the preview arrow, if any).
    **/
    public function setAnnotations(rings:Array<HexAnnotation>, arrows:Array<ArrowAnnotation>):Void
    {
        this.rings = rings;
        this.arrows = arrows;
        redraw();
    }

    /**
        Shows `arrow` on top of the annotations, or removes the preview if `null`.
    **/
    public function setPreviewArrow(arrow:Null<ArrowAnnotation>):Void
    {
        previewArrow = arrow;
        redraw();
    }

    public function setPalette(palette:BoardPalette):Void
    {
        this.palette = palette;
        redraw();
    }

    public function redraw():Void
    {
        layer.clear();

        for (ring in rings)
            drawRing(ring);
        for (arrow in arrows)
            drawArrow(arrow);
        if (previewArrow != null)
            drawArrow(previewArrow);
    }

    private function drawRing(ring:HexAnnotation):Void
    {
        var center:BoardPoint = projection.hexCenter(ring.hex);
        var circle:SVGCircleBuilder = layer.svgCircle(center.x, center.y, RING_RADIUS);
        circle.fill({color: "transparent"});
        circle.stroke({color: palette.annotationMark(ring.color), thickness: RING_THICKNESS});
        circle.element.setAttribute("stroke-opacity", OPACITY);
    }

    private function drawArrow(arrow:ArrowAnnotation):Void
    {
        var vertices:Array<BoardPoint> = ArrowGeometry.outline(projection.hexCenter(arrow.from), projection.hexCenter(arrow.to));

        var path:SVGPathBuilder = layer.svgPath(vertices[0].x, vertices[0].y);
        for (i in 1...vertices.length)
            path.lineTo(vertices[i].x, vertices[i].y);
        path.close();
        path.fill({color: palette.annotationMark(arrow.color)});
        path.element.setAttribute("fill-opacity", OPACITY);
    }
}
