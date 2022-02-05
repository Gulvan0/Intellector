package gameboard.states;

class NeutralState extends BasePlayableState
{
    private override function abortMove()
    {
        //* Do nothing
    }

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        var pressedPiece:Null<Piece> = boardInstance.getPiece(location);

        if (boardInstance.behavior.returnToCurrentOnLMB())
            boardInstance.applyScrolling(End);
        
        if (pressedPiece == null || !boardInstance.behavior.allowedToMove(pressedPiece))
            return;

        boardInstance.getHex(location).showLayer(LMB);
        if (!boardInstance.behavior.markersDisabled())
            boardInstance.addMarkers(location);
        boardInstance.startPieceDragging(location);
        boardInstance.state = new DraggingState(boardInstance, location, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.behavior.allowedToMove(boardInstance.getPiece(location));
    }

    public override function onLMBReleased(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
    }
}