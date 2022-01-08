package gameboard.states;

class BaseNeutralState extends BaseState
{
    private function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        throw "To be overriden";
    }

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        var pressedPiece:Null<Piece> = boardInstance.getFigure(location);

        boardInstance.applyScrolling(End);

        if (pressedPiece == null || pressedPiece.color != playerColor)
            return;

        boardInstance.getHex(location).showLayer(LMB);
        boardInstance.addMarkers(location);
        boardInstance.startPieceDragging(location);
        boardInstance.state = getDraggingState(location);
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