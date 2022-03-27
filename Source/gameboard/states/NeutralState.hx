package gameboard.states;

import struct.IntPoint;

class NeutralState extends BasePlayableState
{
    public override function abortMove()
    {
        //* Do nothing
    }

    public override function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool)
    {
        var pressedPiece:Null<Piece> = boardInstance.getPiece(location);

        if (boardInstance.behavior.returnToCurrentOnLMB() && !boardInstance.plyHistory.isAtEnd())
        {
            boardInstance.applyScrolling(End);
            return;
        }
        
        if (pressedPiece == null || !boardInstance.behavior.allowedToMove(pressedPiece))
        {
            boardInstance.behavior.onVoidClick();
            return;
        }

        boardInstance.getHex(location).showLayer(LMB);
        if (!boardInstance.behavior.markersDisabled())
            boardInstance.addMarkers(location);
        boardInstance.startPieceDragging(location);
        boardInstance.state = new DraggingState(boardInstance, location, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        var piece = boardInstance.getPiece(location);
        if (piece == null)
            return false;
        else
            return boardInstance.behavior.allowedToMove(piece);
    }

    public override function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
    }
}