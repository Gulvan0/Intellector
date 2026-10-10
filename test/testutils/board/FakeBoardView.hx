package testutils.board;

import client.ui.common.board.BoardPoint;
import client.ui.common.board.BoardView;
import client.ui.common.board.PositionChangeCause;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import morestd.Signal;

/** Records what tools draw; `setPosition` drops piece changes, like `BoardSurface` **/
class FakeBoardView implements BoardView
{
    public final onPositionChanged:Signal<PositionChangeCause> = new Signal();

    /** Every `setPosition` call's cause, in order **/
    public final causes:Array<PositionChangeCause> = [];

    private var position:Position;
    private var markers:Array<Int> = [];
    // by scalar coord of the piece's own hex
    private var pointPlacements:Map<Int, BoardPoint> = [];
    private var hexPlacements:Map<Int, HexCoords> = [];
    private var hiddenHexes:Map<Int, Bool> = [];

    public function new(position:Position)
    {
        this.position = position;
    }

    public function getPosition():Position
    {
        return position;
    }

    public function setPosition(position:Position, cause:PositionChangeCause):Void
    {
        this.position = position;
        pointPlacements = [];
        hexPlacements = [];
        hiddenHexes = [];
        causes.push(cause);
        onPositionChanged.dispatch(cause);
    }

    public function addMoveMarker(coords:HexCoords):Void
    {
        markers.push(coords.toScalarCoord());
    }

    public function clearMoveMarkers():Void
    {
        markers = [];
    }

    public function movePieceToPoint(coords:HexCoords, point:BoardPoint):Void
    {
        hexPlacements.remove(coords.toScalarCoord());
        pointPlacements.set(coords.toScalarCoord(), point);
    }

    public function movePieceToHex(coords:HexCoords, destination:HexCoords):Void
    {
        pointPlacements.remove(coords.toScalarCoord());
        hexPlacements.set(coords.toScalarCoord(), destination);
    }

    public function resetPiece(coords:HexCoords):Void
    {
        pointPlacements.remove(coords.toScalarCoord());
        hexPlacements.remove(coords.toScalarCoord());
    }

    public function setPieceVisible(coords:HexCoords, visible:Bool):Void
    {
        if (visible)
            hiddenHexes.remove(coords.toScalarCoord());
        else
            hiddenHexes.set(coords.toScalarCoord(), true);
    }

    /** The move markers drawn, as ascending scalar coordinates **/
    public function markerScalars():Array<Int>
    {
        var result:Array<Int> = markers.copy();
        result.sort(Reflect.compare);
        return result;
    }

    /** Where the piece on `coords` is drawn following the pointer, `null` if it isn't **/
    public function pointOf(coords:HexCoords):Null<BoardPoint>
    {
        return pointPlacements.get(coords.toScalarCoord());
    }

    /** The hex the piece on `coords` is drawn on instead of its own, `null` if none **/
    public function hexOf(coords:HexCoords):Null<HexCoords>
    {
        return hexPlacements.get(coords.toScalarCoord());
    }

    /** Whether every piece is drawn on its own hex **/
    public function piecesInPlace():Bool
    {
        return !pointPlacements.iterator().hasNext() && !hexPlacements.iterator().hasNext();
    }

    public function isHidden(coords:HexCoords):Bool
    {
        return hiddenHexes.exists(coords.toScalarCoord());
    }
}
