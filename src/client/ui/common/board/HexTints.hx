package client.ui.common.board;

import client.ui.common.board.layers.HexGridLayer;
import intellectorboard.primitives.hex.HexCoords;

using Lambda;

private typedef TintCoverage =
{
    tint:HexTint,
    hexes:Map<Int, HexCoords>
}

/**
    Resolves which `HexTint` each hex shows: every writer only says which hexes its own tint
    covers, and a hex shows the highest-priority tint covering it (`HexTint`'s declaration order),
    or its base fill if none does. Paints the result onto a `HexGridLayer`, whose per-hex fills it
    is the only writer of. One per board, created by whoever assembles the board.
**/
class HexTints
{
    private final grid:HexGridLayer;
    private var palette:BoardPalette;
    private var coverages:Array<TintCoverage> = [];

    public function new(grid:HexGridLayer, palette:BoardPalette)
    {
        this.grid = grid;
        this.palette = palette;
    }

    public function add(tint:HexTint, coords:HexCoords):Void
    {
        coverageOf(tint).hexes.set(coords.toScalarCoord(), coords);
        repaint(coords);
    }

    public function remove(tint:HexTint, coords:HexCoords):Void
    {
        var coverage:Null<TintCoverage> = existingCoverageOf(tint);
        if (coverage != null && coverage.hexes.remove(coords.toScalarCoord()))
            repaint(coords);
    }

    /**
        Makes `tint` cover exactly `hexes`.
    **/
    public function set(tint:HexTint, hexes:Array<HexCoords>):Void
    {
        var coverage:TintCoverage = coverageOf(tint);
        var previous:Array<HexCoords> = coverage.hexes.array();

        coverage.hexes = [for (coords in hexes) coords.toScalarCoord() => coords];

        for (coords in previous)
            repaint(coords);
        for (coords in hexes)
            repaint(coords);
    }

    public function clear(tint:HexTint):Void
    {
        set(tint, []);
    }

    public function setPalette(palette:BoardPalette):Void
    {
        this.palette = palette;

        for (coverage in coverages)
            for (coords in coverage.hexes)
                repaint(coords);
    }

    private function existingCoverageOf(tint:HexTint):Null<TintCoverage>
    {
        return coverages.find(coverage -> Type.enumEq(coverage.tint, tint));
    }

    private function coverageOf(tint:HexTint):TintCoverage
    {
        var coverage:Null<TintCoverage> = existingCoverageOf(tint);
        if (coverage == null)
        {
            coverage = {tint: tint, hexes: []};
            coverages.push(coverage);
        }
        return coverage;
    }

    private function repaint(coords:HexCoords):Void
    {
        var scalarCoord:Int = coords.toScalarCoord();
        var shown:Null<HexTint> = null;

        for (coverage in coverages)
            if (coverage.hexes.exists(scalarCoord) && (shown == null || Type.enumIndex(coverage.tint) < Type.enumIndex(shown)))
                shown = coverage.tint;

        if (shown == null)
            grid.resetHexFill(coords);
        else
        {
            var color:ShadedColor = colorOf(shown);
            grid.setHexFill(coords, coords.isDark() ? color.dark : color.light);
        }
    }

    private function colorOf(tint:HexTint):ShadedColor
    {
        return switch tint {
            case DepartureHover: palette.departureHover;
            case DestinationHover: palette.destinationHover;
            case EditorHover: palette.editorHover;
            case SelectedDeparture: palette.selectedDeparture;
            case PromptAnchor: palette.promptAnchor;
            case AnnotationFill(color): palette.annotationFill(color);
            case Premove: palette.premove;
            case LastMove: palette.lastMove;
        }
    }
}
