package client.ui.common.board;

import client.Assets;
import haxefolio.graphics.SvgSurface;
import intellectorboard.position.Position;
import intellectorboard.position.OccupiedHexesIterator;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.hex.HexCoordsIterator;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;

/**
    Static rendering of a `Position` on the hex board - geometry and rendering only, no
    interaction. A non-interactive preview (challenge overlay, incoming-challenge widget, game/
    study list rows) is a bare `BoardSurface`; interaction is added later by attaching a
    controller to one of these, never by subclassing it.
**/
class BoardSurface extends SvgSurface
{
    private static inline final LABEL_FONT_SIZE:Float = BoardGeometry.SIDE_LENGTH * 0.35;
    private static inline final LABEL_GAP:Float = BoardGeometry.SIDE_LENGTH * 0.15;
    private static inline final LABEL_ROW_HEIGHT:Float = LABEL_FONT_SIZE * 1.3;

    private static inline final HEX_FILL_LIGHT:String = "#ffcf9f";
    private static inline final HEX_FILL_DARK:String = "#d18b47";
    private static inline final HEX_BORDER:String = "#664126";
    private static inline final ROW_NUMBER_ON_LIGHT:String = "#664126";
    private static inline final ROW_NUMBER_ON_DARK:String = "#FFD8B2";

    private var position:Position;
    private var orientation:PieceColor;
    private var coordinatesMode:BoardCoordinatesMode;

    private final boardOriginX:Float;
    private final boardOriginY:Float;
    private final fileLetterY:Float;

    public function new(position:Position, orientation:PieceColor, coordinatesMode:BoardCoordinatesMode)
    {
        var gridWidth:Float = 2 * BoardGeometry.GRID_HALF_WIDTH + BoardGeometry.BORDER_THICKNESS;
        var gridHeight:Float = 2 * BoardGeometry.GRID_HALF_HEIGHT + BoardGeometry.BORDER_THICKNESS;
        var labelsShown:Bool = coordinatesMode != None;
        var viewBoxHeight:Float = gridHeight + (labelsShown ? LABEL_GAP + LABEL_ROW_HEIGHT : 0);

        super(gridWidth, viewBoxHeight);

        this.boardOriginX = gridWidth / 2;
        this.boardOriginY = gridHeight / 2;
        this.fileLetterY = gridHeight + LABEL_GAP + LABEL_ROW_HEIGHT / 2;

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

        for (coords in new HexCoordsIterator())
            drawHex(coords);

        if (coordinatesMode != None)
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

        if (coordinatesMode == All)
            drawRowNumber(coords, x, y, dark);
    }

    private function drawRowNumber(coords:HexCoords, hexX:Float, hexY:Float, dark:Bool):Void
    {
        var rowNumber:Int = 7 - coords.j - coords.i % 2;
        var label = svgText('$rowNumber', hexX - 0.85 * BoardGeometry.SIDE_LENGTH, hexY);
        label.fill({color: dark ? ROW_NUMBER_ON_DARK : ROW_NUMBER_ON_LIGHT});
        label.font({size: Std.int(LABEL_FONT_SIZE), anchor: "start"});
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

            var label = svgText(String.fromCharCode('a'.code + i), x, fileLetterY);
            label.fill({color: HEX_BORDER});
            label.font({size: Std.int(LABEL_FONT_SIZE), anchor: "middle"});
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

        svgImage(Assets.pieceImage(kind, color), x - width / 2, y - height / 2, width, height);
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
    private static function pieceAspectRatio(kind:PieceKind):Float
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
}
