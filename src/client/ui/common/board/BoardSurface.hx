package client.ui.common.board;

import client.datatypes.BoardCoordinatesMode;
import client.ui.common.board.layers.AnnotationLayer;
import client.ui.common.board.layers.CoordinateLabelsLayer;
import client.ui.common.board.layers.GlyphLayer;
import client.ui.common.board.layers.HexGridLayer;
import client.ui.common.board.layers.PiecesLayer;
import haxefolio.graphics.SvgLayer;
import haxefolio.graphics.SvgSurface;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import morestd.Signal;
import morestd.VoidSignal;

/**
    Renders a `Position`, with no interaction or preferences; tools add interaction from outside.
    Layers, bottom to top: hex grid, coordinate labels, pieces, move markers, annotations, the
    dragged piece.
**/
class BoardSurface extends SvgSurface implements BoardView
{
    /** For `HexTints` alone to paint fills on **/
    public final grid:HexGridLayer;

    /** For `BoardAnnotations` and `AnnotationTool` to draw on **/
    public final annotationLayer:AnnotationLayer;

    /** Dispatched after a flip or a coordinates mode change, for things positioned against the board **/
    public final onGeometryChanged:VoidSignal = new VoidSignal();

    /** Dispatched after `setPosition`, with the cause it was given **/
    public final onPositionChanged:Signal<PositionChangeCause> = new Signal();

    private final projection:BoardProjection;
    private final labels:CoordinateLabelsLayer;
    private final pieces:PiecesLayer;
    private final glyphs:GlyphLayer;

    private var position:Position;
    private var coordinatesMode:BoardCoordinatesMode;

    public function new(position:Position, orientation:PieceColor, coordinatesMode:BoardCoordinatesMode, ?palette:BoardPalette)
    {
        super(BoardGeometry.GRID_WIDTH, boardHeight(coordinatesMode));

        if (palette == null)
            palette = BoardPalette.DEFAULT;

        this.position = position;
        this.coordinatesMode = coordinatesMode;

        projection = new BoardProjection(orientation, {x: BoardGeometry.GRID_WIDTH / 2, y: BoardGeometry.GRID_HEIGHT / 2});
        grid = new HexGridLayer(addLayer(), projection, palette);
        labels = new CoordinateLabelsLayer(addLayer(), projection, palette, coordinatesMode);
        var piecesLayer:SvgLayer = addLayer();
        glyphs = new GlyphLayer(addLayer(), projection, palette);
        annotationLayer = new AnnotationLayer(addLayer(), projection, palette);
        // last, so the dragged piece is drawn above everything
        pieces = new PiecesLayer(piecesLayer, addLayer(), projection, position);

        grid.redraw();
        labels.redraw();
        pieces.redraw();
    }

    private static function boardHeight(coordinatesMode:BoardCoordinatesMode):Float
    {
        return BoardGeometry.GRID_HEIGHT + CoordinateLabelsLayer.stripHeight(coordinatesMode);
    }

    public function getPosition():Position
    {
        return position;
    }

    public function getOrientation():PieceColor
    {
        return projection.orientation;
    }

    /** Displays `position`, dropping gesture changes to the pieces (but not move markers) **/
    public function setPosition(position:Position, cause:PositionChangeCause):Void
    {
        this.position = position;
        pieces.setPosition(position);
        onPositionChanged.dispatch(cause);
    }

    /** Flips the board so `orientation` is at the bottom, keeping everything drawn **/
    public function setOrientation(orientation:PieceColor):Void
    {
        if (orientation == projection.orientation)
            return;

        projection.orientation = orientation;

        grid.redraw();
        labels.redraw();
        pieces.redraw();
        glyphs.redraw();
        annotationLayer.redraw();

        onGeometryChanged.dispatch();
    }

    public function setCoordinatesMode(coordinatesMode:BoardCoordinatesMode):Void
    {
        if (coordinatesMode == this.coordinatesMode)
            return;

        this.coordinatesMode = coordinatesMode;
        setViewBox(BoardGeometry.GRID_WIDTH, boardHeight(coordinatesMode));
        labels.setMode(coordinatesMode);

        onGeometryChanged.dispatch();
    }

    public function setPalette(palette:BoardPalette):Void
    {
        grid.setPalette(palette);
        labels.setPalette(palette);
        glyphs.setPalette(palette);
        annotationLayer.setPalette(palette);
    }

    /** Draws a move-destination marker at `coords`: a dot, or a ring on a capture **/
    public function addMoveMarker(coords:HexCoords):Void
    {
        glyphs.addMoveMarker(coords, !position.get(coords).isEmpty());
    }

    public function clearMoveMarkers():Void
    {
        glyphs.clearMoveMarkers();
    }

    /** Draws the piece on `coords` centered on `point`, above everything on the board **/
    public function movePieceToPoint(coords:HexCoords, point:BoardPoint):Void
    {
        pieces.movePieceToPoint(coords, point);
    }

    /** Draws the piece on `coords` on `destination`, as though it already moved there **/
    public function movePieceToHex(coords:HexCoords, destination:HexCoords):Void
    {
        pieces.movePieceToHex(coords, destination);
    }

    /** Draws the piece on `coords` back on its own hex **/
    public function resetPiece(coords:HexCoords):Void
    {
        pieces.resetPiece(coords);
    }

    /** Shows or hides the piece on `coords`, if any, until the next `setPosition` **/
    public function setPieceVisible(coords:HexCoords, visible:Bool):Void
    {
        pieces.setPieceVisible(coords, visible);
    }

    /** The hex under the viewport point `(clientX, clientY)`, or `null` off the board **/
    public function hexAtClientPoint(clientX:Float, clientY:Float):Null<HexCoords>
    {
        return projection.hexAt(clientPointToViewBox(clientX, clientY));
    }

    /** The board point under the viewport point `(clientX, clientY)` **/
    public function clientPointToBoardPoint(clientX:Float, clientY:Float):BoardPoint
    {
        return clientPointToViewBox(clientX, clientY);
    }

    /** The center of `coords`, in viewport coordinates **/
    public function hexClientCenter(coords:HexCoords):{x:Float, y:Float}
    {
        var center:BoardPoint = projection.hexCenter(coords);
        return viewBoxPointToClient(center.x, center.y);
    }

    /** A hex's current on-screen height, in pixels **/
    public function hexClientHeight():Float
    {
        return BoardGeometry.HEX_HEIGHT * viewBoxUnitInPixels();
    }

    /** Where `coords` is drawn horizontally: -1 for the leftmost file, 0 the middle, 1 the rightmost **/
    public function horizontalPosition(coords:HexCoords):Float
    {
        return projection.horizontalPosition(coords);
    }

    /** Whether the hex at `coords` is drawn below the board's horizontal midline **/
    public function isInLowerHalf(coords:HexCoords):Bool
    {
        return projection.isInLowerHalf(coords);
    }
}
