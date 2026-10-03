package client.ui.common.board.layers;

import client.datatypes.BoardCoordinatesMode;
import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardPalette;
import client.ui.common.board.BoardPoint;
import client.ui.common.board.BoardProjection;
import haxe.ui.backend.html5.svg.SVGTextBuilder;
import haxefolio.graphics.SvgLayer;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.hex.HexCoordsIterator;

/**
    File letters (in a strip below the grid) and row numbers (inside each hex), per the
    coordinates mode.
**/
class CoordinateLabelsLayer implements BoardLayer
{
    // Constrained by hex size - must fit inside a single hex alongside a piece.
    private static inline final ROW_NUMBER_FONT_SIZE:Float = BoardGeometry.SIDE_LENGTH * 0.35;

    // Unconstrained by hex size - sits in its own dedicated strip below the grid, sized to fit it.
    private static inline final FILE_LETTER_FONT_SIZE:Float = BoardGeometry.SIDE_LENGTH * 0.7;

    private static inline final FILE_LETTER_GAP:Float = BoardGeometry.SIDE_LENGTH * 0.04;
    private static inline final FILE_LETTER_ROW_HEIGHT:Float = FILE_LETTER_FONT_SIZE * 1.3;

    private final layer:SvgLayer;
    private final projection:BoardProjection;
    private var palette:BoardPalette;
    private var mode:BoardCoordinatesMode;

    public function new(layer:SvgLayer, projection:BoardProjection, palette:BoardPalette, mode:BoardCoordinatesMode)
    {
        this.layer = layer;
        this.projection = projection;
        this.palette = palette;
        this.mode = mode;
    }

    /**
        How far below the grid the labels reach in `mode`: the height of the file-letter strip, or
        0 when there's none.
    **/
    public static function stripHeight(mode:BoardCoordinatesMode):Float
    {
        return mode == NONE ? 0 : FILE_LETTER_GAP + FILE_LETTER_ROW_HEIGHT;
    }

    public function setMode(mode:BoardCoordinatesMode):Void
    {
        this.mode = mode;
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

        if (mode == ALL)
            for (coords in new HexCoordsIterator())
                drawRowNumber(coords);

        if (mode != NONE)
            drawFileLetters();
    }

    private function drawRowNumber(coords:HexCoords):Void
    {
        var center:BoardPoint = projection.hexCenter(coords);
        var rowNumber:Int = 7 - coords.j - coords.i % 2;

        var label:SVGTextBuilder = layer.svgText('$rowNumber', center.x - 0.85 * BoardGeometry.SIDE_LENGTH, center.y);
        label.fill({color: coords.isDark() ? palette.rowNumber.dark : palette.rowNumber.light});
        label.font({size: Std.int(ROW_NUMBER_FONT_SIZE), anchor: "start"});
        label.element.setAttribute("dominant-baseline", "central");
        label.element.setAttribute("font-weight", "bold");
    }

    private function drawFileLetters():Void
    {
        for (i in 0...9)
        {
            var bottomRow:Int = projection.orientation == White ? 6 - i % 2 : 0;
            var center:BoardPoint = projection.hexCenter(new HexCoords(i, bottomRow));

            /*
                Each file's own bottom border, not one shared row - adjoining files' bottom hexes
                sit at different heights (the staggered-column grid).
            */
            var bottomBorderY:Float = center.y + BoardGeometry.HEX_HEIGHT / 2;
            var y:Float = bottomBorderY + FILE_LETTER_GAP + FILE_LETTER_ROW_HEIGHT / 2;

            var label:SVGTextBuilder = layer.svgText(String.fromCharCode('a'.code + i), center.x, y);
            label.fill({color: palette.fileLetter});
            label.font({size: Std.int(FILE_LETTER_FONT_SIZE), anchor: "middle"});
            label.element.setAttribute("dominant-baseline", "central");
            label.element.setAttribute("font-weight", "bold");
        }
    }
}
