package client.ui.common.board.layers;

import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardPalette;
import client.ui.common.board.BoardPoint;
import client.ui.common.board.BoardProjection;
import haxe.ui.backend.html5.svg.SVGCircleBuilder;
import haxefolio.graphics.SvgLayer;
import intellectorboard.primitives.hex.HexCoords;

private typedef MoveMarker =
{
    coords:HexCoords,
    capture:Bool
}

/**
    Move markers: a dot on an empty destination, a ring around an occupied one (a capture).
**/
class GlyphLayer implements BoardLayer
{
    private static inline final DOT_RADIUS:Float = BoardGeometry.SIDE_LENGTH * 0.2;
    private static inline final RING_RADIUS:Float = BoardGeometry.SIDE_LENGTH * 0.8;
    private static inline final RING_THICKNESS:Float = BoardGeometry.SIDE_LENGTH * 0.1;

    private final layer:SvgLayer;
    private final projection:BoardProjection;
    private var palette:BoardPalette;

    private var markers:Array<MoveMarker> = [];

    public function new(layer:SvgLayer, projection:BoardProjection, palette:BoardPalette)
    {
        this.layer = layer;
        this.projection = projection;
        this.palette = palette;
    }

    /**
        Marks `coords` as a destination: a ring if `capture`, a dot otherwise.
    **/
    public function addMoveMarker(coords:HexCoords, capture:Bool):Void
    {
        var marker:MoveMarker = {coords: coords, capture: capture};
        markers.push(marker);
        drawMarker(marker);
    }

    public function clearMoveMarkers():Void
    {
        if (markers.length == 0)
            return;

        markers = [];
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

        for (marker in markers)
            drawMarker(marker);
    }

    private function drawMarker(marker:MoveMarker):Void
    {
        var center:BoardPoint = projection.hexCenter(marker.coords);
        var circle:SVGCircleBuilder = layer.svgCircle(center.x, center.y, marker.capture ? RING_RADIUS : DOT_RADIUS);

        if (marker.capture)
        {
            circle.fill({color: "transparent"});
            circle.stroke({color: palette.moveMarker, thickness: RING_THICKNESS});
        }
        else
            circle.fill({color: palette.moveMarker});
    }
}
