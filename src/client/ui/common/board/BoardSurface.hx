package client.ui.common.board;

import client.Assets;
import client.datatypes.BoardCoordinatesMode;
import haxefolio.graphics.SvgSurface;
import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxe.ui.backend.html5.svg.SVGImageBuilder;
import haxe.ui.backend.html5.svg.SVGCircleBuilder;
import intellectorboard.position.Position;
import intellectorboard.position.OccupiedHexesIterator;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.hex.HexCoordsIterator;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;

private typedef PieceHandle =
{
    image:SVGImageBuilder,
    width:Float,
    height:Float
}

/**
    Static rendering of a `Position` on the hex board - geometry and rendering only, no
    interaction. A non-interactive preview (challenge overlay, incoming-challenge widget, game/
    study list rows) is a bare `BoardSurface`; interaction is added later by attaching a
    controller to one of these, never by subclassing it.
**/
class BoardSurface extends SvgSurface
{
    // Constrained by hex size - must fit inside a single hex alongside a piece.
    private static inline final ROW_NUMBER_FONT_SIZE:Float = BoardGeometry.SIDE_LENGTH * 0.35;

    // Unconstrained by hex size - sits in its own dedicated strip below the grid, sized to fit it.
    private static inline final FILE_LABEL_FONT_SIZE:Float = BoardGeometry.SIDE_LENGTH * 0.7;

    private static inline final LABEL_GAP:Float = BoardGeometry.SIDE_LENGTH * 0.04;
    private static inline final LABEL_ROW_HEIGHT:Float = FILE_LABEL_FONT_SIZE * 1.3;

    private static inline final HEX_FILL_LIGHT:String = "#ffcf9f";
    private static inline final HEX_FILL_DARK:String = "#d18b47";
    private static inline final HEX_BORDER:String = "#664126";
    private static inline final ROW_NUMBER_ON_LIGHT:String = "#664126";
    private static inline final ROW_NUMBER_ON_DARK:String = "#FFD8B2";

    private static inline final MARKER_COLOR:String = "#333333";
    private static inline final MARKER_DOT_RADIUS:Float = BoardGeometry.SIDE_LENGTH * 0.2;
    private static inline final MARKER_RING_RADIUS:Float = BoardGeometry.SIDE_LENGTH * 0.8;
    private static inline final MARKER_RING_THICKNESS:Float = BoardGeometry.SIDE_LENGTH * 0.1;

    private var position:Position;
    private var orientation:PieceColor;
    private var coordinatesMode:BoardCoordinatesMode;

    private var hexPaths:Map<Int, SVGPathBuilder> = [];
    private var pieceHandles:Map<Int, PieceHandle> = [];

    private final boardOriginX:Float;
    private final boardOriginY:Float;

    public function new(position:Position, orientation:PieceColor, coordinatesMode:BoardCoordinatesMode)
    {
        var gridWidth:Float = 2 * BoardGeometry.GRID_HALF_WIDTH + BoardGeometry.BORDER_THICKNESS;
        var gridHeight:Float = 2 * BoardGeometry.GRID_HALF_HEIGHT + BoardGeometry.BORDER_THICKNESS;
        var labelsShown:Bool = coordinatesMode != NONE;
        var viewBoxHeight:Float = gridHeight + (labelsShown ? LABEL_GAP + LABEL_ROW_HEIGHT : 0);

        super(gridWidth, viewBoxHeight);

        this.boardOriginX = gridWidth / 2;
        this.boardOriginY = gridHeight / 2;

        this.position = position;
        this.orientation = orientation;
        this.coordinatesMode = coordinatesMode;

        redraw();
    }

    public function setPosition(position:Position):Void
    {
        this.position = position;
        redraw();
    }

    public function setOrientation(orientation:PieceColor):Void
    {
        this.orientation = orientation;
        redraw();
    }

    public function setCoordinatesMode(coordinatesMode:BoardCoordinatesMode):Void
    {
        this.coordinatesMode = coordinatesMode;
        redraw();
    }

    private function redraw():Void
    {
        clear();
        hexPaths = [];
        pieceHandles = [];

        for (coords in new HexCoordsIterator())
            drawHex(coords);

        if (coordinatesMode != NONE)
            drawFileLetters();

        for (occupiedHex in new OccupiedHexesIterator(position))
            drawPiece(occupiedHex.coords, occupiedHex.piece.type, occupiedHex.piece.color);
    }

    private function drawHex(coords:HexCoords):Void
    {
        var center = BoardGeometry.hexCenter(coords, orientation);
        var x:Float = boardOriginX + center.x;
        var y:Float = boardOriginY + center.y;
        var dark:Bool = coords.isDark();
        var vertices = BoardGeometry.hexVertices(x, y);

        var hexPath = svgPath(vertices[0].x, vertices[0].y);
        for (i in 1...vertices.length)
            hexPath.lineTo(vertices[i].x, vertices[i].y);
        hexPath.close();
        hexPath.fill({color: dark ? HEX_FILL_DARK : HEX_FILL_LIGHT});
        hexPath.stroke({color: HEX_BORDER, thickness: BoardGeometry.BORDER_THICKNESS});
        hexPaths.set(coords.toScalarCoord(), hexPath);

        if (coordinatesMode == ALL)
            drawRowNumber(coords, x, y, dark);
    }

    private function drawRowNumber(coords:HexCoords, hexX:Float, hexY:Float, dark:Bool):Void
    {
        var rowNumber:Int = 7 - coords.j - coords.i % 2;
        var label = svgText('$rowNumber', hexX - 0.85 * BoardGeometry.SIDE_LENGTH, hexY);
        label.fill({color: dark ? ROW_NUMBER_ON_DARK : ROW_NUMBER_ON_LIGHT});
        label.font({size: Std.int(ROW_NUMBER_FONT_SIZE), anchor: "start"});
        label.element.setAttribute("dominant-baseline", "central");
        label.element.setAttribute("font-weight", "bold");
    }

    private function drawFileLetters():Void
    {
        for (i in 0...9)
        {
            var bottomRow:Int = orientation == White ? 6 - i % 2 : 0;
            var bottomHex:HexCoords = new HexCoords(i, bottomRow);
            var center = BoardGeometry.hexCenter(bottomHex, orientation);
            var x:Float = boardOriginX + center.x;

            // Each file's own bottom border, not one shared row - adjoining files' bottom hexes
            // sit at different heights (the staggered-column grid).
            var bottomBorderY:Float = boardOriginY + center.y + BoardGeometry.HEX_HEIGHT / 2;
            var y:Float = bottomBorderY + LABEL_GAP + LABEL_ROW_HEIGHT / 2;

            var label = svgText(String.fromCharCode('a'.code + i), x, y);
            label.fill({color: HEX_BORDER});
            label.font({size: Std.int(FILE_LABEL_FONT_SIZE), anchor: "middle"});
            label.element.setAttribute("dominant-baseline", "central");
            label.element.setAttribute("font-weight", "bold");
        }
    }

    private function drawPiece(coords:HexCoords, kind:PieceKind, color:PieceColor):Void
    {
        var center = BoardGeometry.hexCenter(coords, orientation);
        var x:Float = boardOriginX + center.x;
        var y:Float = boardOriginY + center.y;

        var height:Float = BoardGeometry.HEX_HEIGHT * 0.85 * pieceRelativeScale(kind);
        var width:Float = height * pieceAspectRatio(kind);

        var image = svgImage(Assets.pieceImage(kind, color), x - width / 2, y - height / 2, width, height);
        pieceHandles.set(coords.toScalarCoord(), {image: image, width: width, height: height});
    }

    private static function pieceRelativeScale(kind:PieceKind):Float
    {
        return switch kind
        {
            case Progressor: 0.7;
            case Liberator, Defensor: 0.9;
            default: 1;
        }
    }

    /*
        Each piece kind's own SVG asset has a fixed aspect ratio (width/height of its own viewBox),
        close enough between the white/black variants of the same kind to treat as one constant -
        the couple-percent difference between color variants isn't visually distinguishable.
    */
    public static function pieceAspectRatio(kind:PieceKind):Float
    {
        return switch kind
        {
            case Progressor: 1.08887;
            case Aggressor: 0.66371;
            case Dominator: 0.66793;
            case Liberator: 0.79958;
            case Defensor: 0.65379;
            case Intellector: 0.62913;
        }
    }

    /**
        The hex under `(clientX, clientY)` (a native DOM event's viewport coordinates), or `null`
        when the point isn't over the board at all.
    **/
    public function hexAtClientPoint(clientX:Float, clientY:Float):Null<HexCoords>
    {
        var point = clientPointToViewBox(clientX, clientY);
        return BoardGeometry.hexAt(point.x - boardOriginX, point.y - boardOriginY, orientation);
    }

    /**
        The board-center-relative point of `(clientX, clientY)` (the same space `movePieceTo`
        takes), for a controller that needs the raw point rather than a snapped hex - e.g. to keep
        a dragged piece under the cursor.
    **/
    public function clientPointToBoardPoint(clientX:Float, clientY:Float):{x:Float, y:Float}
    {
        var point = clientPointToViewBox(clientX, clientY);
        return {x: point.x - boardOriginX, y: point.y - boardOriginY};
    }

    /**
        Overrides `coords`'s hex fill with `color` - a single writer's semantic tint (hover,
        selection, etc; see knowledge/plans/board_plan.md's priority list), resolved by that
        writer, not by `BoardSurface` itself. Invalidated by the next `setPosition`/
        `setOrientation`/`setCoordinatesMode` call, like every other glyph.
    **/
    public function setHexFill(coords:HexCoords, color:String):Void
    {
        var path = hexPaths.get(coords.toScalarCoord());
        if (path != null)
            path.fill({color: color});
    }

    /**
        Reverts `coords`'s hex fill back to its base dark/light color.
    **/
    public function resetHexFill(coords:HexCoords):Void
    {
        setHexFill(coords, coords.isDark() ? HEX_FILL_DARK : HEX_FILL_LIGHT);
    }

    /**
        Draws a move-destination glyph at `coords` - a filled dot if empty, a hollow ring if
        occupied (a capture). Returns a live handle; remove it later with `handle.element.remove()`
        (`BoardSurface` keeps no ownership of glyphs it hands out).
    **/
    public function addMoveMarker(coords:HexCoords):SVGCircleBuilder
    {
        var center = BoardGeometry.hexCenter(coords, orientation);
        var x:Float = boardOriginX + center.x;
        var y:Float = boardOriginY + center.y;

        var marker = svgCircle(x, y, position.get(coords).isEmpty() ? MARKER_DOT_RADIUS : MARKER_RING_RADIUS);

        if (position.get(coords).isEmpty())
            marker.fill({color: MARKER_COLOR});
        else
        {
            marker.fill({color: "transparent"});
            marker.stroke({color: MARKER_COLOR, thickness: MARKER_RING_THICKNESS});
        }

        return marker;
    }

    /**
        Repositions the piece drawn at `fromCoords` to the board-center-relative point
        `(boardX, boardY)` (the same space `clientPointToBoardPoint` returns) - a plain `x`/`y`
        attribute write, no redraw.
    **/
    public function movePieceTo(fromCoords:HexCoords, boardX:Float, boardY:Float):Void
    {
        var handle = pieceHandles.get(fromCoords.toScalarCoord());
        if (handle != null)
            handle.image.position(boardOriginX + boardX - handle.width / 2, boardOriginY + boardY - handle.height / 2);
    }

    /**
        Snaps the piece at `coords` back to its resting position - undoes any `movePieceTo` calls
        made while dragging it, e.g. when a gesture is aborted before a move is committed.
    **/
    public function resetPiecePosition(coords:HexCoords):Void
    {
        var center = BoardGeometry.hexCenter(coords, orientation);
        movePieceTo(coords, center.x, center.y);
    }

    /**
        Draws the piece that stands on `fromCoords` on top of `toCoords`'s hex, as though it
        already moved there - a purely visual stand-in while a move's details are still being
        chosen. Undo with `resetPiecePosition(fromCoords)`.
    **/
    public function movePieceToHex(fromCoords:HexCoords, toCoords:HexCoords):Void
    {
        var center = BoardGeometry.hexCenter(toCoords, orientation);
        movePieceTo(fromCoords, center.x, center.y);
        bringPieceToFront(fromCoords);
    }

    /**
        Shows or hides the piece drawn at `coords` (no effect on an empty hex). Like every other
        glyph, reset by the next `setPosition`/`setOrientation`/`setCoordinatesMode` call.
    **/
    public function setPieceVisible(coords:HexCoords, visible:Bool):Void
    {
        var handle = pieceHandles.get(coords.toScalarCoord());
        if (handle != null)
            handle.image.element.style.visibility = visible ? "visible" : "hidden";
    }

    /**
        The center of the hex at `coords`, in viewport (`clientX`/`clientY`) coordinates.
    **/
    public function hexClientCenter(coords:HexCoords):{x:Float, y:Float}
    {
        var center = BoardGeometry.hexCenter(coords, orientation);
        return viewBoxPointToClient(boardOriginX + center.x, boardOriginY + center.y);
    }

    /**
        The hex's current on-screen height, in pixels (the board scales with its container).
    **/
    public function hexClientHeight():Float
    {
        return BoardGeometry.HEX_HEIGHT * viewBoxUnitInPixels();
    }

    /**
        How far left or right of the board's vertical midline the hex at `coords` is drawn: -1 for
        the leftmost file, 1 for the rightmost, 0 for the middle one.
    **/
    public function horizontalPosition(coords:HexCoords):Float
    {
        return BoardGeometry.hexCenter(coords, orientation).x / (6 * BoardGeometry.SIDE_LENGTH);
    }

    /**
        Whether the hex at `coords` is drawn below the board's horizontal midline.
    **/
    public function isInLowerHalf(coords:HexCoords):Bool
    {
        return BoardGeometry.hexCenter(coords, orientation).y > 0;
    }

    /**
        Moves the piece at `coords` to the end of the SVG's paint order, so it draws on top of
        every other hex/piece/glyph while dragged (SVG has no `z-index`; paint order is the only
        stacking control).
    **/
    public function bringPieceToFront(coords:HexCoords):Void
    {
        var handle = pieceHandles.get(coords.toScalarCoord());
        if (handle != null)
            handle.image.element.parentNode.appendChild(handle.image.element);
    }
}
