package gfx.game.behaviours;

import net.shared.variation.VariationPath;
import net.shared.variation.VariationNode;
import net.shared.board.RawPly;
import gfx.game.events.GameboardEvent;
import gfx.game.models.AnalysisBoardModel;

class NormalAnalysis extends AnalysisRelatedBehaviour 
{
    private function performPly(ply:RawPly) 
    {
        var currentNodePath:VariationPath = model.getSelectedNodePath();
        var currentNode:VariationNode = model.variation.getNode(currentNodePath);
        var existingChildNum:Null<Int> = currentNode.getChildNumByPly(ply);

        if (existingChildNum == null)
        {
            var childPath:VariationPath = model.variation.addChild(currentNodePath, ply);
            model.selectedBranch = childPath;
            model.shownMovePointer = childPath.length;
            modelUpdateHandler(VariationUpdated);
        }
        else
        {
            var childPath:VariationPath = currentNodePath.childPath(existingChildNum);
            if (!model.selectedBranch.isDescendantOf(childPath))
                model.selectedBranch = model.variation.getFullMainlinePath(childPath);
            model.shownMovePointer = childPath.length;
            modelUpdateHandler(SelectedVariationNodeUpdated);
        }
                
        model.deriveShownSituationFromOtherParams();
        modelUpdateHandler(ShownSituationUpdated);
            
        model.deriveInteractivityModeFromOtherParams();
        modelUpdateHandler(InteractivityModeUpdated);
    }

    public function handleGameboardEvent(event:GameboardEvent)
    {
        switch event 
        {
            case MoveAttempted(from, to, options):
                constructMove(from, to, options, false, performPly);
            default:
        }
    }

    public function new(model:AnalysisBoardModel)
    {
        super(model);
    }    
}