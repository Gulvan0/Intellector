package gameboard.states;

private enum Transition
{
    ToNeutral;
    ToSelected;
}

class DraggingState extends BasePlayableState
{
    private var dragStartLocation:IntPoint;
    private var draggedPiece:Piece;

    public function onEntered()
    {
        draggedPiece = boardInstance.getPiece(dragStartLocation);
        draggedPiece.cacheAsBitmap = true;
        boardInstance.bringPieceToFront(draggedPiece);
        draggedPiece.startDrag(true);

        boardInstance.getHex(dragStartLocation).showLayer(LMB);

        if (!boardInstance.behavior.markersDisabled())
            boardInstance.addMarkers(dragStartLocation);
    }

    private function exit(transition:Transition)
    {
        draggedPiece.stopDrag();
        draggedPiece.cacheAsBitmap = false;
        draggedPiece.reposition(dragStartLocation, boardInstance);

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

    public function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        if (location != null && location.equals(dragStartLocation))
            exit(ToSelected);
        else
            exit(ToNeutral);

        if (location != null && boardInstance.behavior.movePossible(dragStartLocation, location))
            askMoveDetails(dragStartLocation, location, shiftPressed, ctrlPressed);
    }

    public function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.behavior.movePossible(dragStartLocation, location);
    }
    
    private function isHoverStrong():Bool
    {
        return false;
    }

    public function new(dragStartLocation:IntPoint)
    {
        this.dragStartLocation = dragStartLocation;
    }
}