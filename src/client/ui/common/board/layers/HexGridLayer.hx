package client.ui.common.board.layers;

import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardPalette;
import client.ui.common.board.BoardPoint;
import client.ui.common.board.BoardProjection;
import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxefolio.graphics.SvgLayer;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.hex.HexCoordsIterator;

/** The hex shapes: their border, their base fill and any per-hex fill overriding it **/
class HexGridLayer implements BoardLayer
{
    private final layer:SvgLayer;
    private final projection:BoardProjection;
    private var palette:BoardPalette;

    // by scalar coord; an absent hex shows its base fill
    private var fills:Map<Int, String> = [];
    private var hexPaths:Map<Int, SVGPathBuilder> = [];

    public function new(layer:SvgLayer, projection:BoardProjection, palette:BoardPalette)
    {
        this.layer = layer;
        this.projection = projection;
        this.palette = palette;
    }

    /** Overrides the fill at `coords`; only `HexTints` calls this, to respect tint priority **/
    public function setHexFill(coords:HexCoords, color:String):Void
    {
        fills.set(coords.toScalarCoord(), color);
        applyFill(coords);
    }

    /** Reverts `coords` to its base fill; only `HexTints` calls this **/
    public function resetHexFill(coords:HexCoords):Void
    {
        if (fills.remove(coords.toScalarCoord()))
            applyFill(coords);
    }

    public function setPalette(palette:BoardPalette):Void
    {
        this.palette = palette;
        redraw();
    }

    public function redraw():Void
    {
        layer.clear();
        hexPaths = [];

        for (coords in new HexCoordsIterator())
            drawHex(coords);
    }

    private function drawHex(coords:HexCoords):Void
    {
        var vertices:Array<BoardPoint> = BoardGeometry.hexVertices(projection.hexCenter(coords));

        var hexPath:SVGPathBuilder = layer.svgPath(vertices[0].x, vertices[0].y);
        for (i in 1...vertices.length)
            hexPath.lineTo(vertices[i].x, vertices[i].y);
        hexPath.close();
        hexPath.stroke({color: palette.border, thickness: BoardGeometry.BORDER_THICKNESS});
        hexPaths.set(coords.toScalarCoord(), hexPath);

        applyFill(coords);
    }

    private function applyFill(coords:HexCoords):Void
    {
        var hexPath:Null<SVGPathBuilder> = hexPaths.get(coords.toScalarCoord());
        if (hexPath == null)
            return;

        var fill:Null<String> = fills.get(coords.toScalarCoord());
        if (fill == null)
            fill = coords.isDark() ? palette.baseFill.dark : palette.baseFill.light;
        hexPath.fill({color: fill});
    }
}
