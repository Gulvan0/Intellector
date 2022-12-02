package gameboard.behaviors;

import gameboard.states.HexSelectionState;
import gameboard.states.NeutralState;
import gfx.analysis.PeripheralEvent;
import utils.exceptions.AlreadyInitializedException;
import net.shared.ServerEvent;
import net.shared.PieceColor;
import utils.AssetManager;

abstract class EditorBehavior implements IBehavior 
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
            case ApplyChangesRequested:
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
                        boardInstance.state = new HexSelectionState(true);
                        boardInstance.behavior = new EditorDeleteBehavior();
                    case Set(type, color):
                        boardInstance.state = new HexSelectionState(false);
                        boardInstance.behavior = new EditorSetBehavior(type, color);
                    default:
                }
            default:
        }
    }

    public function onChangesApplied()
    {
        boardInstance._startingSituation = boardInstance.shownSituation;
        boardInstance._currentSituation = boardInstance.shownSituation;
        boardInstance.plyHistory.clear();

        boardInstance.state = new NeutralState();
        boardInstance.behavior = new AnalysisBehavior();
    }

    public function onChangesDiscarded()
    {
        boardInstance.setShownSituation(boardInstance.currentSituation);
        boardInstance.highlightLastMove();

        boardInstance.state = new NeutralState();
        boardInstance.behavior = new AnalysisBehavior();
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