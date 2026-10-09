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

/** Move markers: a dot on an empty destination, a ring around an occupied one (a capture) **/
class GlyphLayer implements BoardLayer
{
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

    /** Marks `coords` as a destination: a ring if `capture`, a dot otherwise **/
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
        var radiusInSideLengthUnits:Float = marker.capture ? StyleVars.BOARD_MARKER_RING_RADIUS_SLU : StyleVars.BOARD_MARKER_DOT_RADIUS_SLU;
        var circle:SVGCircleBuilder = layer.svgCircle(center.x, center.y, radiusInSideLengthUnits * BoardGeometry.SIDE_LENGTH);

        if (marker.capture)
        {
            circle.fill({color: "transparent"});
            circle.stroke({color: palette.moveMarker, thickness: StyleVars.BOARD_MARKER_RING_THICKNESS_SLU * BoardGeometry.SIDE_LENGTH});
        }
        else
            circle.fill({color: palette.moveMarker});
    }
}
