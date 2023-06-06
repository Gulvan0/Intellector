package gfx.game.behaviours;

import net.shared.variation.Variation;
import net.shared.board.Situation;
import net.shared.variation.NodeRemovalOutput;
import net.shared.variation.VariationPath;
import net.shared.dataobj.OfferAction;
import net.shared.dataobj.OfferKind;
import net.shared.dataobj.StudyInfo;
import gfx.popups.ShareDialog;
import net.shared.PieceColor.opposite;
import net.shared.ServerEvent;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.events.GameboardEvent;
import gfx.game.events.ChatboxEvent;
import gfx.game.events.VariationViewEvent;
import gfx.game.events.PositionEditorEvent;
import gfx.game.models.AnalysisBoardModel;

using Lambda;

abstract class AnalysisRelatedBehaviour extends BaseBehaviour
{
    private var model:AnalysisBoardModel;

	public abstract function handleGameboardEvent(event:GameboardEvent):Void;

    public function new(model:AnalysisBoardModel)
    {
        super(model);
        this.model = model;
    }

    private function onScrolledToPastMove()
    {
        //* Do nothing
    }

	public function handleNetEvent(event:ServerEvent) 
    {
        //* Do nothing
    }

	public function handleGlobalEvent(event:GlobalEvent) 
    {
        //* Do nothing
    }

	public function handleChatboxEvent(event:ChatboxEvent) 
    {
        throw 'ChatboxEvent occured in analysis related behaviour: $event';
    }

	public function customOnEntered() 
    {
        //* Do nothing
    }

    private function onExploredStudyUpdated(studyInfo:StudyInfo)
    {
        model.exploredStudyInfo = studyInfo;
    }

    private function onSharePressed()
    {
        var shareDialog:ShareDialog = new ShareDialog();
        shareDialog.initInAnalysis(model.getShownSituation(), model.getOrientation(), model.getVariation(), onExploredStudyUpdated, model.getExploredStudyInfo());
        shareDialog.showShareDialog();
    }

    private function onResignPressed()
    {
        throw 'Resign button was pressed, yet it shouldn\'t have been present in analysis board';
    }
    
    private function onAbortPressed()
    {
        throw 'Abort button was pressed, yet it shouldn\'t have been present in analysis board';
    }

    private function onOfferActionRequested(kind:OfferKind, action:OfferAction)
    {
        throw 'Offers should be disabled in analysis board, got action $action/$kind';
    }
    
    private function onAddTimePressed()
    {
        throw 'AddTime button was pressed, yet it shouldn\'t have been present in analysis board';
    }
    
    private function onRematchPressed()
    {
        throw 'Rematch button was pressed, yet it shouldn\'t have been present in analysis board';
    }
    
    private function onAnalyzePressed()
    {
        throw 'Analyze button was pressed, yet it shouldn\'t have been present in analysis board';
    }

    private function closeEditor()
    {
        model.editorMode = null;
        modelUpdateHandler(EditorModeUpdated);
        model.editorSituation = null;
        modelUpdateHandler(EditorSituationUpdated);
        model.deriveShownSituationFromOtherParams();
        modelUpdateHandler(ShownSituationUpdated);
        model.deriveInteractivityModeFromOtherParams();
        modelUpdateHandler(InteractivityModeUpdated);
    }

    private function onEditPositionPressed()
    {
        model.editorSituation = model.getShownSituation();
        modelUpdateHandler(EditorSituationUpdated);
        model.editorMode = Move;
        modelUpdateHandler(EditorModeUpdated);
        model.deriveShownSituationFromOtherParams();
        modelUpdateHandler(ShownSituationUpdated);
        model.deriveInteractivityModeFromOtherParams();
        modelUpdateHandler(InteractivityModeUpdated);
    }

    private function onViewReportPressed()
    {
        //TODO: Add in the next update
    }

	public function handleVariationViewEvent(event:VariationViewEvent) 
    {
        switch event 
        {
            case NodeSelected(path):
                if (model.selectedBranch.equals(path))
                    return;

                if (!model.selectedBranch.isDescendantOf(path))
                    model.selectedBranch = model.variation.getFullMainlinePath(path);

                model.shownMovePointer = path.length;
                modelUpdateHandler(SelectedVariationNodeUpdated);
                
                model.deriveShownSituationFromOtherParams();
                modelUpdateHandler(ShownSituationUpdated);

                model.deriveInteractivityModeFromOtherParams();
                modelUpdateHandler(InteractivityModeUpdated);
            case NodeRemoved(path):
                if (path.isRoot())
                    return;

                var nodeRemovalOutput:NodeRemovalOutput = model.variation.removeNode(path);

                if (model.selectedBranch.isDescendantOf(path))
                {
                    var parentPath:VariationPath = path.parentPath();
                    model.selectedBranch = parentPath;
                    model.shownMovePointer = parentPath.length;
                
                    model.deriveShownSituationFromOtherParams();
                    modelUpdateHandler(ShownSituationUpdated);
                }
                else
                {
                    var selectedBranchRemapping = nodeRemovalOutput.pathUpdates.find(pair -> pair.oldPath.equals(model.getSelectedBranch()));
                    if (selectedBranchRemapping != null)
                        model.selectedBranch = selectedBranchRemapping.newPath;
                }

                modelUpdateHandler(VariationUpdated);
                
                model.deriveInteractivityModeFromOtherParams();
                modelUpdateHandler(InteractivityModeUpdated);
        }
    }

	public function handlePositionEditorEvent(event:PositionEditorEvent) 
    {
        switch event 
        {
            case EditModeChangeRequested(mode):
                model.editorMode = mode;
                modelUpdateHandler(EditorModeUpdated);
                model.deriveInteractivityModeFromOtherParams();
                modelUpdateHandler(InteractivityModeUpdated);
            case TurnColorChangeRequested(color):
                model.editorSituation = model.editorSituation.copy(color);
                modelUpdateHandler(EditorSituationUpdated);
                model.deriveShownSituationFromOtherParams();
                modelUpdateHandler(ShownSituationUpdated);
            case SituationImported(situation):
                model.editorSituation = situation;
                modelUpdateHandler(EditorSituationUpdated);
                model.deriveShownSituationFromOtherParams();
                modelUpdateHandler(ShownSituationUpdated);
            case ClearRequested:
                model.editorSituation = Situation.empty();
                modelUpdateHandler(EditorSituationUpdated);
                model.deriveShownSituationFromOtherParams();
                modelUpdateHandler(ShownSituationUpdated);
            case ResetRequested:
                model.editorSituation = model.getSelectedNodeSituation();
                modelUpdateHandler(EditorSituationUpdated);
                model.deriveShownSituationFromOtherParams();
                modelUpdateHandler(ShownSituationUpdated);
            case StartPosRequested:
                model.editorSituation = Situation.defaultStarting();
                modelUpdateHandler(EditorSituationUpdated);
                model.deriveShownSituationFromOtherParams();
                modelUpdateHandler(ShownSituationUpdated);
            case OrientationChangeRequested:
                model.orientation = opposite(model.orientation);
                modelUpdateHandler(OrientationUpdated);
            case ApplyChangesRequested:
                model.variation = new Variation(model.editorSituation);
                modelUpdateHandler(VariationUpdated);
                closeEditor();
            case DiscardChangesRequested:
                closeEditor();
        }
    }
}