package gfx.game.board.states;

import haxe.ui.events.MouseEvent;
import gfx.game.board.subcomponents.Piece;
import haxe.ui.geom.Point;
import net.shared.board.HexCoords;

class DraggingState implements IState
{
    private var boardInstance:GameBoard;
    public var cursorLocation(default, null):Null<HexCoords>;

    private var dragStartLocation:HexCoords;
    private var dragStartScreenCoords:Point;
    private var isDestinationAllowed:HexCoords->Bool;

    private var draggedPiece:Piece;
    private var dragOffset:Point;
    private var dragBlocked:Bool;

    public function onEntered() 
    {
        if (cursorLocation != null && isDestinationAllowed(cursorLocation))
            boardInstance.showHexLayer(cursorLocation, Hover);
        else
            boardInstance.hideLayerForEveryHex(Hover);
    }

    public function exit() 
    {
        dragBlocked = true;
        draggedPiece.setCenterAt(boardInstance.hexCoords(dragStartLocation));

        boardInstance.getHex(dragStartLocation).hideLayer(SelectedForMove);
        boardInstance.hideLayerForEveryHex(Hover);
        boardInstance.removeAllMarkers();
    }

    public function onLMBPressed(location:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        //* Do nothing
    }

    public function onMouseMoved(newCursorLocation:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        if (equal(cursorLocation, newCursorLocation))
            return;

        if (newCursorLocation != null && isDestinationAllowed(newCursorLocation))
            boardInstance.showHexLayer(newCursorLocation, Hover);
        else
            boardInstance.hideLayerForEveryHex(Hover);

        if (!dragBlocked)
        {
            var newPos:Point = dragOffset.sum(new Point(boardInstance.lastMouseMoveEvent.screenX, boardInstance.lastMouseMoveEvent.screenY));
            draggedPiece.left = newPos.x;
            draggedPiece.top = newPos.y;
        }

        cursorLocation = newCursorLocation;
    }

    public function onLMBReleased(location:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        if (location != null && location.equals(dragStartLocation))
        {
            dragBlocked = true;
            draggedPiece.setCenterAt(boardInstance.hexCoords(dragStartLocation));
            boardInstance.state = new SelectedState(boardInstance, cursorLocation, location, isDestinationAllowed);
        }
        else
        {
            exit();
            boardInstance.state = new NeutralState(boardInstance, cursorLocation);

            if (location != null && isDestinationAllowed(location))
                if (boardInstance.mode.match(PlySelection(_)))
                    boardInstance.eventHandler(MoveAttempted(dragStartLocation, location, {
                        fastPromotion: originalEvent.shiftKey? AutoPromoteToDominator : Ask,
                        fastChameleon: originalEvent.shiftKey? AutoAccept : originalEvent.ctrlKey? AutoDecline : Ask
                    }));
                else
                    boardInstance.eventHandler(FreeMovePerformed(dragStartLocation, location));
        }
    }

    public function new(boardInstance:GameBoard, cursorLocation:Null<HexCoords>, dragStartLocation:HexCoords, dragStartScreenCoords:Point, isDestinationAllowed:HexCoords->Bool) 
    {
        this.boardInstance = boardInstance;
        this.cursorLocation = cursorLocation;

        this.dragStartLocation = dragStartLocation;
        this.dragStartScreenCoords = dragStartScreenCoords;
        this.isDestinationAllowed = isDestinationAllowed;

        this.draggedPiece = boardInstance.getPiece(dragStartLocation);
        this.dragOffset = new Point(draggedPiece.left - dragStartScreenCoords.x, draggedPiece.top - dragStartScreenCoords.y);
        this.dragBlocked = false;
    }
}