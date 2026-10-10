package client.ui.common.board;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import morestd.Signal;

/** What tools, annotations and premoves need of the board they work on (`BoardSurface`) **/
interface BoardView
{
    /** Dispatched after `setPosition`, with the cause it was given **/
    public final onPositionChanged:Signal<PositionChangeCause>;

    public function getPosition():Position;

    /** Displays `position`, dropping gesture changes to the pieces (but not move markers) **/
    public function setPosition(position:Position, cause:PositionChangeCause):Void;

    /** Draws a move-destination marker at `coords` **/
    public function addMoveMarker(coords:HexCoords):Void;

    public function clearMoveMarkers():Void;

    /** Draws the piece on `coords` centered on `point`, above everything on the board **/
    public function movePieceToPoint(coords:HexCoords, point:BoardPoint):Void;

    /** Draws the piece on `coords` on `destination`, as though it already moved there **/
    public function movePieceToHex(coords:HexCoords, destination:HexCoords):Void;

    /** Draws the piece on `coords` back on its own hex **/
    public function resetPiece(coords:HexCoords):Void;

    /** Shows or hides the piece on `coords`, if any, until the next `setPosition` **/
    public function setPieceVisible(coords:HexCoords, visible:Bool):Void;
}
