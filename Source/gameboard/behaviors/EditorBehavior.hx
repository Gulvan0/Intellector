package gameboard.behaviors;

import struct.Situation;
import gameboard.states.HexSelectionState;
import gameboard.states.NeutralState;
import gfx.analysis.PeripheralEvent;
import utils.exceptions.AlreadyInitializedException;
import struct.Ply;
import struct.IntPoint;
import net.ServerEvent;
import struct.ReversiblePly;
import struct.PieceColor;
import utils.AssetManager;

abstract class EditorBehavior implements IBehavior 
{
    private var boardInstance:GameBoard;

    public function handleNetEvent(event:ServerEvent):Void
	{
        //* Do nothing
    }

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case ClearRequested:
                boardInstance.setShownSituation(Situation.empty());
            case ResetRequested:
                boardInstance.setShownSituation(boardInstance.currentSituation);
            case StartPosRequested:
                boardInstance.setShownSituation(Situation.starting());
            case OrientationChangeRequested:
                boardInstance.revertOrientation();
            case ConstructSituationRequested(situation):
                boardInstance.setShownSituation(situation);
            case TurnColorChanged(newTurnColor):
                var updatedSituation = boardInstance.shownSituation;
                updatedSituation.turnColor = newTurnColor;
                boardInstance.setShownSituation(updatedSituation);
            case ApplyChangesRequested(turnColor):
                onChangesApplied();
            case DiscardChangesRequested:
                onChangesDiscarded();
            case EditModeChanged(newEditMode):
                switch newEditMode 
                {
                    case Move:
                        boardInstance.state = new NeutralState();
                        boardInstance.behavior = new EditorFreeMoveBehavior();
                    case Delete:
                        boardInstance.state = new HexSelectionState();
                        boardInstance.behavior = new EditorDeleteBehavior();
                    case Set(type, color):
                        boardInstance.state = new HexSelectionState();
                        boardInstance.behavior = new EditorSetBehavior(type, color);
                    default:
                }
            default:
        }
    }

    public function onChangesApplied()
    {
        boardInstance.startingSituation = boardInstance.shownSituation.copy();
        boardInstance.currentSituation = boardInstance.shownSituation.copy();
        boardInstance.plyHistory.clear();

        boardInstance.state = new NeutralState();
        boardInstance.behavior = new AnalysisBehavior(boardInstance.currentSituation.turnColor);
    }

    public function onChangesDiscarded()
    {
        boardInstance.setShownSituation(boardInstance.currentSituation);

        boardInstance.state = new NeutralState();
        boardInstance.behavior = new AnalysisBehavior(boardInstance.currentSituation.turnColor);
    }
    
    public function movePossible(from:IntPoint, to:IntPoint):Bool
	{
        return true;
    }
    
    public function allowedToMove(piece:Piece):Bool
	{
        return true;
    }
    
    public function returnToCurrentOnLMB():Bool
	{
        return false;
    }
    
    public function onVoidClick()
	{
        //* Do nothing
    }

    public function onAboutToScrollAway()
    {
        //* Do nothing
    }
    
    public function markersDisabled():Bool
    {
        return true;
    }

    public function hoverDisabled():Bool
    {
        return false;
    }

    public function init(board:GameBoard)
    {
        if (this.boardInstance != null)
            throw new AlreadyInitializedException();
        this.boardInstance = board;
    }
}