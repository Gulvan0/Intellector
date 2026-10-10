package testutils.board;

import client.ui.common.board.BoardPalette;
import client.ui.common.board.HexFillTarget;
import client.ui.common.board.ShadedColor;
import intellectorboard.primitives.hex.HexCoords;

/** Records per-hex fills; pair with `PALETTE`, whose colors are named after their palette entry **/
class FakeHexFills implements HexFillTarget
{
    public static final PALETTE:BoardPalette = {
        baseFill: shaded("baseFill"),
        border: "border",
        fileLetter: "fileLetter",
        rowNumber: shaded("rowNumber"),
        moveMarker: "moveMarker",
        departureHover: shaded("departureHover"),
        selectedDeparture: shaded("selectedDeparture"),
        destinationHover: shaded("destinationHover"),
        promptAnchor: shaded("promptAnchor"),
        editorHover: shaded("editorHover"),
        premove: shaded("premove"),
        lastMove: shaded("lastMove"),
        annotationFillRed: shaded("annotationFillRed"),
        annotationFillBlue: shaded("annotationFillBlue"),
        annotationFillGreen: shaded("annotationFillGreen"),
        annotationFillYellow: shaded("annotationFillYellow"),
        annotationMarkRed: "annotationMarkRed",
        annotationMarkBlue: "annotationMarkBlue",
        annotationMarkGreen: "annotationMarkGreen",
        annotationMarkYellow: "annotationMarkYellow"
    };

    private var fills:Map<Int, String> = [];

    public function new() {}

    private static function shaded(name:String):ShadedColor
    {
        return {light: '$name/light', dark: '$name/dark'};
    }

    public function setHexFill(coords:HexCoords, color:String):Void
    {
        fills.set(coords.toScalarCoord(), color);
    }

    public function resetHexFill(coords:HexCoords):Void
    {
        fills.remove(coords.toScalarCoord());
    }

    /** The exact color filling `coords`, `null` for its base fill **/
    public function colorAt(coords:HexCoords):Null<String>
    {
        return fills.get(coords.toScalarCoord());
    }

    /** The `PALETTE` entry filling `coords` (e.g. "premove"), `null` for its base fill **/
    public function entryAt(coords:HexCoords):Null<String>
    {
        var color:Null<String> = colorAt(coords);
        return color != null ? color.split("/")[0] : null;
    }

    /** Every hex with a fill, as scalar coordinates **/
    public function filledScalars():Array<Int>
    {
        var result:Array<Int> = [for (scalarCoord in fills.keys()) scalarCoord];
        result.sort(Reflect.compare);
        return result;
    }
}
