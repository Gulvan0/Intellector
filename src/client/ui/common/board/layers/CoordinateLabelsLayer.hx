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

/** File letters (in a strip below the grid) and row numbers (inside each hex), per the coordinates mode **/
class CoordinateLabelsLayer implements BoardLayer
{
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

    /** The height of the file-letter strip below the grid in `mode`; 0 if there's none **/
    public static function stripHeight(mode:BoardCoordinatesMode):Float
    {
        return mode == NONE ? 0 : (StyleVars.BOARD_FILE_LETTER_GAP_SLU + StyleVars.BOARD_FILE_LETTER_ROW_HEIGHT_SLU) * BoardGeometry.SIDE_LENGTH;
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

        var inset:Float = StyleVars.BOARD_ROW_NUMBER_INSET_SLU * BoardGeometry.SIDE_LENGTH;

        var label:SVGTextBuilder = layer.svgText('$rowNumber', center.x - inset, center.y);
        label.fill({color: coords.isDark() ? palette.rowNumber.dark : palette.rowNumber.light});
        label.font({anchor: "start"});
        label.element.setAttribute("font-size", Std.string(StyleVars.BOARD_ROW_NUMBER_FONT_SIZE_SLU * BoardGeometry.SIDE_LENGTH));
        label.element.setAttribute("dominant-baseline", "central");
        label.element.setAttribute("font-weight", "bold");
    }

    private function drawFileLetters():Void
    {
        for (i in 0...9)
        {
            var bottomRow:Int = projection.orientation == White ? 6 - i % 2 : 0;
            var center:BoardPoint = projection.hexCenter(new HexCoords(i, bottomRow));

            // per file: adjoining files' bottom hexes sit at different heights
            var bottomBorderY:Float = center.y + BoardGeometry.HEX_HEIGHT / 2;
            var y:Float = bottomBorderY + (StyleVars.BOARD_FILE_LETTER_GAP_SLU + StyleVars.BOARD_FILE_LETTER_ROW_HEIGHT_SLU / 2) * BoardGeometry.SIDE_LENGTH;

            var label:SVGTextBuilder = layer.svgText(String.fromCharCode('a'.code + i), center.x, y);
            label.fill({color: palette.fileLetter});
            label.font({anchor: "middle"});
        label.element.setAttribute("font-size", Std.string(StyleVars.BOARD_FILE_LETTER_FONT_SIZE_SLU * BoardGeometry.SIDE_LENGTH));
            label.element.setAttribute("dominant-baseline", "central");
            label.element.setAttribute("font-weight", "bold");
        }
    }
}
