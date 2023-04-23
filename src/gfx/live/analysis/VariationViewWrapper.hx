package gfx.live.analysis;

import gfx.live.models.AnalysisBoardModel;
import gfx.live.events.VariationViewEvent;
import gfx.live.interfaces.IGameComponentObserver;
import gfx.live.events.ModelUpdateEvent;
import gfx.live.models.ReadOnlyModel;
import GlobalBroadcaster.GlobalEvent;
import gfx.live.interfaces.IGameComponent;
import haxe.ui.containers.Box;

class VariationViewWrapper extends Box implements IGameComponent
{
    private var variationView:IVariationView;

    private var analysisModel:AnalysisBoardModel;
    private var eventHandler:VariationViewEvent->Void;

    public function init(model:ReadOnlyModel, gameScreen:IGameComponentObserver):Void
    {
        switch model 
        {
            case AnalysisBoard(model):
                analysisModel = model;
                eventHandler = gameScreen.handleVariationViewEvent;
            default:
                throw "VariationViewWrapper can only be used with AnalysisBoardModel";
        }

        refreshVariationView();

        GlobalBroadcaster.addObserver(this);
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent):Void
    {
        switch event
        {
            case VariationUpdated:
                variationView.updateVariation(analysisModel.getVariation(), analysisModel.getSelectedNodePath(), analysisModel.getSelectedBranch());
            case SelectedVariationNodeUpdated:
                variationView.updateSelectedNode(analysisModel.getSelectedNodePath(), analysisModel.getSelectedBranch());
            default:
        }
    }

    public function destroy():Void
    {
        GlobalBroadcaster.removeObserver(this);
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case PreferenceUpdated(BranchingType):
                refreshVariationView();
            default:
        }
    }

    private function refreshVariationView()
    {
        removeAllComponents();

        /* TODO: variationView = switch Preferences.branchingTabType.get() 
        {
            case Tree:
            case Outline:
            case PlainText:
        }*/

        addComponent(variationView.asComponent());
        variationView.init(analysisModel, eventHandler);
    }

    public function new()
    {
        super();
    }
}