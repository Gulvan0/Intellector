package gameboard.states;

class PlayerMoveNeutralState extends BaseState
{
    public override function onLMBPressed(location:Null<IntPoint>)
    {
        var pressedPiece:Null<Piece> = boardInstance.getFigure(location);

        boardInstance.applyScrolling(End);

        if (pressedPiece == null || pressedPiece.color != playerColor)
            return;

        boardInstance.getHex(location).showLayer(LMB);
        boardInstance.addMarkers(location);
        boardInstance.startPieceDragging(location);
        boardInstance.state = new PlayerMoveDraggingState(boardInstance, location);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.shownSituation.get(location).color == boardInstance.playerColor;
    }

    public override function onLMBReleased(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public override function handleNetEvent(event:NetEvent)
    {
        //TODO: Fill
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
    }
}