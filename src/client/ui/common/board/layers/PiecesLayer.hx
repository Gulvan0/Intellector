package client.ui.common.board.layers;

import client.ui.Assets;
import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardPoint;
import client.ui.common.board.BoardProjection;
import haxe.ui.backend.html5.svg.SVGImageBuilder;
import haxefolio.graphics.SvgLayer;
import intellectorboard.position.OccupiedHexesIterator;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.piece.PieceKind;

// Where a piece is drawn instead of on its own hex, for the duration of a gesture.
private enum PieceDisplacement
{
    // Dragged: centered on a free point (a point, not a hex, so it stays under the cursor).
    AtPoint(point:BoardPoint);
    // Drawn as though already moved, while the move's details are still being chosen.
    OnHex(coords:HexCoords);
}

private typedef PieceImage =
{
    image:SVGImageBuilder,
    width:Float,
    height:Float
}

/**
    The piece images: the position, plus temporary changes made by a gesture in flight (a piece
    displaced or hidden, the dragged piece lifted above everything else on the board). All of them
    are keyed by the hex the piece stands on in the position, and are dropped by `setPosition`.

    Draws into two groups: its own place in the stack (below markers and annotations), and
    `liftedLayer`, which the assembler puts at the very top of the stack, for the dragged piece
    only.
**/
class PiecesLayer implements BoardLayer
{
    private final layer:SvgLayer;
    private final liftedLayer:SvgLayer;
    private final projection:BoardProjection;
    private var position:Position;

    private var displacements:Map<Int, PieceDisplacement> = [];
    private var hiddenPieces:Map<Int, Bool> = [];
    // The piece drawn in liftedLayer (the dragged one), if any.
    private var liftedPiece:Null<HexCoords> = null;

    private var images:Map<Int, PieceImage> = [];

    public function new(layer:SvgLayer, liftedLayer:SvgLayer, projection:BoardProjection, position:Position)
    {
        this.layer = layer;
        this.liftedLayer = liftedLayer;
        this.projection = projection;
        this.position = position;
    }

    /**
        Shows `position`, dropping every gesture change.
    **/
    public function setPosition(position:Position):Void
    {
        this.position = position;
        displacements = [];
        hiddenPieces = [];
        liftedPiece = null;
        redraw();
    }

    /**
        Draws the piece standing on `coords` centered on `point` instead (dragged), lifted above
        everything else on the board.
    **/
    public function movePieceToPoint(coords:HexCoords, point:BoardPoint):Void
    {
        displacements.set(coords.toScalarCoord(), AtPoint(point));
        placeImage(coords);
        setLifted(coords, true);
    }

    /**
        Draws the piece standing on `coords` on the hex `destination` instead, above the other
        pieces but, like them, below markers and annotations.
    **/
    public function movePieceToHex(coords:HexCoords, destination:HexCoords):Void
    {
        displacements.set(coords.toScalarCoord(), OnHex(destination));
        placeImage(coords);
        setLifted(coords, false);
    }

    /**
        Draws the piece standing on `coords` back on its own hex, among the other pieces.
    **/
    public function resetPiece(coords:HexCoords):Void
    {
        if (!displacements.remove(coords.toScalarCoord()))
            return;

        placeImage(coords);
        setLifted(coords, false);
    }

    /**
        Shows or hides the piece standing on `coords` (no effect on an empty hex).
    **/
    public function setPieceVisible(coords:HexCoords, visible:Bool):Void
    {
        if (visible)
            hiddenPieces.remove(coords.toScalarCoord());
        else
            hiddenPieces.set(coords.toScalarCoord(), true);

        var pieceImage:Null<PieceImage> = images.get(coords.toScalarCoord());
        if (pieceImage != null)
            pieceImage.image.element.style.visibility = visible ? "visible" : "hidden";
    }

    public function redraw():Void
    {
        layer.clear();
        liftedLayer.clear();
        images = [];

        for (occupiedHex in new OccupiedHexesIterator(position))
            drawPiece(occupiedHex.coords, occupiedHex.piece);
    }

    /*
        Moves the piece on `coords` into liftedLayer or back into the own group - in both cases to
        the end of it, as SVG paint order is the only stacking control, so a displaced piece is
        drawn over the other pieces.
    */
    private function setLifted(coords:HexCoords, lifted:Bool):Void
    {
        if (lifted && liftedPiece != null && !liftedPiece.equals(coords))
            setLifted(liftedPiece, false);

        if (lifted)
            liftedPiece = coords;
        else if (liftedPiece != null && liftedPiece.equals(coords))
            liftedPiece = null;

        var pieceImage:Null<PieceImage> = images.get(coords.toScalarCoord());
        if (pieceImage != null)
            (lifted ? liftedLayer : layer).element.appendChild(pieceImage.image.element);
    }

    private function drawPiece(coords:HexCoords, piece:PieceData):Void
    {
        var height:Float = BoardGeometry.HEX_HEIGHT * 0.85 * relativeScale(piece.type);
        var width:Float = height * Assets.pieceAspectRatio(piece.type);
        var lifted:Bool = liftedPiece != null && liftedPiece.equals(coords);
        var image:SVGImageBuilder = (lifted ? liftedLayer : layer).svgImage(Assets.pieceImage(piece.type, piece.color), 0, 0, width, height);

        if (hiddenPieces.exists(coords.toScalarCoord()))
            image.element.style.visibility = "hidden";

        images.set(coords.toScalarCoord(), {image: image, width: width, height: height});
        placeImage(coords);
    }

    // Writes the image's x/y from its displacement (or its own hex) - no redraw.
    private function placeImage(coords:HexCoords):Void
    {
        var pieceImage:Null<PieceImage> = images.get(coords.toScalarCoord());
        if (pieceImage == null)
            return;

        var center:BoardPoint = switch displacements.get(coords.toScalarCoord()) {
            case AtPoint(point): point;
            case OnHex(destination): projection.hexCenter(destination);
            case null: projection.hexCenter(coords);
        }
        pieceImage.image.position(center.x - pieceImage.width / 2, center.y - pieceImage.height / 2);
    }

    private static function relativeScale(kind:PieceKind):Float
    {
        return switch kind {
            case Progressor: 0.7;
            case Liberator, Defensor: 0.9;
            default: 1;
        }
    }
}
