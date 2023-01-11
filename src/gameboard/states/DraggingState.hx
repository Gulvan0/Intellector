package gameboard.states;

import haxe.ui.geom.Point;
import gameboard.components.Piece;
import net.shared.board.HexCoords;

private enum Transition
{
    ToNeutral;
    ToSelected;
}

class DraggingState extends BasePlayableState
{
    private var dragStartLocation:HexCoords;
    private var draggedPiece:Piece;
    private var dragOffset:Point;
    private var dragBlocked:Bool;

    public function onEntered()
    {
        draggedPiece = boardInstance.getPiece(dragStartLocation);
        draggedPiece.moveComponentToFront();
        dragOffset = new Point(draggedPiece.left - boardInstance.lastMouseMoveEvent.screenX, draggedPiece.top - boardInstance.lastMouseMoveEvent.screenY);
        dragBlocked = false;

        boardInstance.getHex(dragStartLocation).showLayer(LMB);

        if (!boardInstance.behavior.markersDisabled())
            boardInstance.addMarkers(dragStartLocation);
    }

    private function exit(transition:Transition)
    {
        dragBlocked = true;
        draggedPiece.setCenterAt(boardInstance.hexCoords(dragStartLocation));

        boardInstance.getHex(dragStartLocation).hideLayer(LMB);

        if (!boardInstance.behavior.markersDisabled())
            boardInstance.removeMarkers(dragStartLocation);

        switch transition 
        {
            case ToNeutral:
                boardInstance.state = new NeutralState();
            case ToSelected:
                boardInstance.state = new SelectedState(dragStartLocation);
        }
    }

    public function exitToNeutral()
    {
        exit(ToNeutral);
    }

    public function onLMBPressed(location:Null<HexCoords>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public override function onMouseMoved(newCursorLocation:Null<HexCoords>) 
    {
        super.onMouseMoved(newCursorLocation);

        if (!dragBlocked)
        {
            var newPos:Point = dragOffset.sum(new Point(boardInstance.lastMouseMoveEvent.screenX, boardInstance.lastMouseMoveEvent.screenY));
            draggedPiece.left = newPos.x;
            draggedPiece.top = newPos.y;
        }
    }

    public function onLMBReleased(location:Null<HexCoords>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        if (location != null && location.equals(dragStartLocation))
            exit(ToSelected);
        else
            exit(ToNeutral);

        if (location != null && boardInstance.behavior.movePossible(dragStartLocation, location))
            askMoveDetails(dragStartLocation, location, shiftPressed, ctrlPressed);
    }

    public function reactsToHover(location:HexCoords):Bool
    {
        return boardInstance.behavior.movePossible(dragStartLocation, location);
    }
    
    private function isHoverStrong():Bool
    {
        return false;
    }

    public function new(dragStartLocation:HexCoords)
    {
        this.dragStartLocation = dragStartLocation;
    }
}