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
    Renders a `Position` on the hex board - rendering only, no interaction and no preferences: it
    displays the plain state it's given. A non-interactive preview is a bare `BoardSurface`;
    interaction is added by tools driving one from outside, never by subclassing it.

    Assembled from layers, bottom to top: the hex grid (`grid`), the coordinate labels, the
    pieces, the move markers, the annotations, and finally the piece being dragged, if any. Each
    redraws only when its own state changes; all of them share one `BoardProjection`.
**/
class BoardSurface extends SvgSurface
{
    /**
        The hex grid layer, for `HexTints` to paint fills on. Nothing else should write to it.
    **/
    public final grid:HexGridLayer;

    /**
        The annotation layer, for `BoardAnnotations` and the annotation tool to draw on.
    **/
    public final annotationLayer:AnnotationLayer;

    /**
        Dispatched after anything drawn on the board may have moved on screen without the board
        being resized: a flip, or a coordinates mode change (the board's height changes with it).
        For outsiders positioned against the board, e.g. an open prompt.
    **/
    public final onGeometryChanged:VoidSignal = new VoidSignal();

    /**
        Dispatched after `setPosition`, with the cause it was given.
    **/
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
        // Last: the dragged piece is drawn above everything else.
        pieces = new PiecesLayer(piecesLayer, addLayer(), projection, position);

        grid.redraw();
        labels.redraw();
        pieces.redraw();
    }

    private static function boardHeight(coordinatesMode:BoardCoordinatesMode):Float
    {
        return BoardGeometry.GRID_HEIGHT + CoordinateLabelsLayer.stripHeight(coordinatesMode);
    }

    /**
        The position currently displayed.
    **/
    public function getPosition():Position
    {
        return position;
    }

    public function getOrientation():PieceColor
    {
        return projection.orientation;
    }

    /**
        Displays `position`, then dispatches `onPositionChanged` with `cause`. Drops every gesture
        change to the pieces (see `movePieceToPoint` and the like); move markers stay until
        cleared by whoever added them.
    **/
    public function setPosition(position:Position, cause:PositionChangeCause):Void
    {
        this.position = position;
        pieces.setPosition(position);
        onPositionChanged.dispatch(cause);
    }

    /**
        Flips the board so that `orientation` is drawn at the bottom. Everything drawn - fills,
        markers, gesture changes to the pieces - is kept and redrawn in the new orientation.
    **/
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

    /**
        Draws a move-destination marker at `coords`: a dot if the hex is empty in the displayed
        position, a ring if it's occupied (a capture).
    **/
    public function addMoveMarker(coords:HexCoords):Void
    {
        glyphs.addMoveMarker(coords, !position.get(coords).isEmpty());
    }

    public function clearMoveMarkers():Void
    {
        glyphs.clearMoveMarkers();
    }

    /**
        Draws the piece standing on `coords` centered on `point` instead, above everything else on
        the board - e.g. to keep a dragged piece under the cursor.
    **/
    public function movePieceToPoint(coords:HexCoords, point:BoardPoint):Void
    {
        pieces.movePieceToPoint(coords, point);
    }

    /**
        Draws the piece standing on `coords` on top of the hex `destination` instead, as though it
        already moved there - a purely visual stand-in while a move's details are being chosen.
    **/
    public function movePieceToHex(coords:HexCoords, destination:HexCoords):Void
    {
        pieces.movePieceToHex(coords, destination);
    }

    /**
        Draws the piece standing on `coords` back on its own hex, undoing `movePieceToPoint`/
        `movePieceToHex`.
    **/
    public function resetPiece(coords:HexCoords):Void
    {
        pieces.resetPiece(coords);
    }

    /**
        Shows or hides the piece standing on `coords` (no effect on an empty hex). Reset by the
        next `setPosition`.
    **/
    public function setPieceVisible(coords:HexCoords, visible:Bool):Void
    {
        pieces.setPieceVisible(coords, visible);
    }

    /**
        The hex under `(clientX, clientY)` (a native DOM event's viewport coordinates), or `null`
        when the point isn't over the board at all.
    **/
    public function hexAtClientPoint(clientX:Float, clientY:Float):Null<HexCoords>
    {
        return projection.hexAt(clientPointToViewBox(clientX, clientY));
    }

    /**
        The board point under `(clientX, clientY)` (the space `movePieceToPoint` takes).
    **/
    public function clientPointToBoardPoint(clientX:Float, clientY:Float):BoardPoint
    {
        return clientPointToViewBox(clientX, clientY);
    }

    /**
        The center of the hex at `coords`, in viewport (`clientX`/`clientY`) coordinates.
    **/
    public function hexClientCenter(coords:HexCoords):{x:Float, y:Float}
    {
        var center:BoardPoint = projection.hexCenter(coords);
        return viewBoxPointToClient(center.x, center.y);
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
        return projection.horizontalPosition(coords);
    }

    /**
        Whether the hex at `coords` is drawn below the board's horizontal midline.
    **/
    public function isInLowerHalf(coords:HexCoords):Bool
    {
        return projection.isInLowerHalf(coords);
    }
}
