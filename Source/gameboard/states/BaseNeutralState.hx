package gameboard.states;

class BaseNeutralState extends BasePlayableState
{
    private function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        throw "To be overriden";
    }

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        var pressedPiece:Null<Piece> = boardInstance.getFigure(location);

        boardInstance.applyScrolling(End); //TODO: Shouldn't activate in AnalysisNeutralState
        //TODO: will analysis board react to a branching move properly? + what will signal it to disregard plys after shownSituation?
        if (pressedPiece == null || pressedPiece.color != playerColor) //TODO: Second condition as an overridable function; will differ for AnalysisNeutralState
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