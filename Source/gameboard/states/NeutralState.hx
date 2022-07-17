package gameboard.states;

import struct.IntPoint;

private enum Transition 
{
    ToDragging(dragStartLocation:IntPoint);
}

class NeutralState extends BasePlayableState
{
    public function onEntered()
    {
        //* Do nothing
    }

    public function exitToNeutral()
    {
        //* Do nothing
    }

    private function exit(transition:Transition)
    {
        switch transition 
        {
            case ToDragging(dragStartLocation):
                boardInstance.state = new DraggingState(dragStartLocation);
        }
    }

    public function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        if (boardInstance.behavior.returnToCurrentOnLMB() && !boardInstance.plyHistory.isAtEnd())
        {
            boardInstance.applyScrolling(End);
            return;
        }
        
        var pressedPiece:Null<Piece> = boardInstance.getPiece(location);

        if (pressedPiece != null && boardInstance.behavior.allowedToMove(pressedPiece))
            exit(ToDragging(location));
        else
            boardInstance.behavior.onVoidClick();
    }

    public function reactsToHover(location:IntPoint):Bool
    {
        var piece = boardInstance.getPiece(location);
        if (piece == null)
            return false;
        else
            return boardInstance.behavior.allowedToMove(piece);
    }
    
    private function isHoverStrong():Bool
    {
        return true;
    }

    public function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function new()
    {
        
    }
}