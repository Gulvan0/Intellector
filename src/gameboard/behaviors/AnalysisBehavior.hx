package gameboard.behaviors;

import gameboard.components.Piece;
import net.shared.board.Rules;
import net.shared.board.HexCoords;
import net.shared.board.RawPly;
import gfx.analysis.PeripheralEvent;
import gameboard.states.NeutralState;
import utils.exceptions.AlreadyInitializedException;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import assets.Audio;
import net.shared.board.MaterializedPly;

class AnalysisBehavior implements IBehavior 
{
    private var boardInstance:GameBoard;

    public function handleNetEvent(event:ServerEvent):Void
	{
        //* Do nothing
    }

    public function onPremovePreferenceUpdated()
    {
        //* Do nothing
    }

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case BranchSelected(branch, _, pointer):
                onBranchSelected(branch, pointer);
            case RevertNeeded(plyCnt):
                boardInstance.revertPlys(plyCnt);
            case OrientationChangeRequested:
                boardInstance.revertOrientation();
            case EditorLaunchRequested:
                boardInstance.removeArrowsAndSelections();
                boardInstance.removeLastMoveHighlighting();
                boardInstance.state = new NeutralState();
                boardInstance.behavior = new EditorFreeMoveBehavior();
            case ScrollBtnPressed(type):
                boardInstance.applyScrolling(type);
            default:
        }
    }

    private function onBranchSelected(plySequence:Array<RawPly>, selectedPlyNum:Int)
    {
        boardInstance.removeArrowsAndSelections();

        boardInstance.plyHistory.clear();
        boardInstance._currentSituation = boardInstance.startingSituation;
        boardInstance.setShownSituation(boardInstance.startingSituation);

        for (ply in plySequence)
            boardInstance.makeMove(ply);

        boardInstance.applyScrolling(Precise(selectedPlyNum));
    }
    
    public function movePossible(from:HexCoords, to:HexCoords):Bool
	{
        return Rules.isMovementPossible(from, to, boardInstance.shownSituation.pieces);
    }
    
    public function allowedToMove(piece:Piece):Bool
	{
        return piece.pieceColor == boardInstance.shownSituation.turnColor;
    }
    
    public function returnToCurrentOnLMB():Bool
	{
        return false;
    }
    
    public function onVoidClick()
	{
        //* Do nothing
    }
    
    public function onMoveChosen(ply:RawPly):Void
	{
        var plyStr:String = ply.toNotation(boardInstance.shownSituation);
        var performedBy:PieceColor = boardInstance.shownSituation.turnColor;
        var matPly:MaterializedPly = ply.toMaterialized(boardInstance.shownSituation);

        Audio.playPlySound(matPly);

        if (boardInstance.plyHistory.isAtEnd())
        {
            boardInstance.makeMove(ply);
            boardInstance.emit(ContinuationMove(ply, plyStr, performedBy));
        }
        else if (boardInstance.plyHistory.equalsNextMove(matPly))
        {
            boardInstance.next();
            boardInstance.emit(SubsequentMove(plyStr, performedBy));
        }
        else
        {
            var droppedMovesCount:Int = boardInstance.plyHistory.length() - boardInstance.plyHistory.pointer;
            boardInstance.revertToShown();
            boardInstance.makeMove(ply);
            boardInstance.emit(BranchingMove(ply, plyStr, performedBy, droppedMovesCount));
        }

        boardInstance.state = new NeutralState();
    }
    
    public function onHexChosen(coords:HexCoords)
    {
        throw "onHexChosen() called while in AnalysisBehavior";
    }
    
    public function markersDisabled():Bool
    {
        return false;
    }

    public function hoverDisabled():Bool
    {
        return false;
    }

    public function onAboutToScrollAway()
    {
        //* Do nothing
    }

    public function init(board:GameBoard)
    {
        if (this.boardInstance != null)
            throw new AlreadyInitializedException();
        this.boardInstance = board;
    }
    
    public function new()
    {
        
    }
}