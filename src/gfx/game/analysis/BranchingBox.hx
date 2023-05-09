package gfx.game.analysis;

import GlobalBroadcaster.IGlobalEventObserver;
import gfx.game.interfaces.IReadOnlyAnalysisBoardModel;
import haxe.ui.containers.VBox;
import gfx.popups.BranchingHelp;
import haxe.ui.events.MouseEvent;
import haxe.ui.core.Component;
import gfx.game.models.AnalysisBoardModel;
import gfx.game.events.VariationViewEvent;
import gfx.game.interfaces.IGameScreen;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.models.ReadOnlyModel;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.interfaces.IGameComponent;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game/branching_box.xml"))
class BranchingBox extends VBox implements IGameComponent implements IGlobalEventObserver
{
    private var variationView:IVariationView;

    private var analysisModel:IReadOnlyAnalysisBoardModel;
    private var eventHandler:VariationViewEvent->Void;

    private var activeWheelHandler:Null<MouseEvent->Void>;

    public function init(model:ReadOnlyModel, gameScreen:IGameScreen):Void
    {
        switch model 
        {
            case AnalysisBoard(model):
                analysisModel = model;
                eventHandler = gameScreen.handleVariationViewEvent;
            default:
                throw "BranchingBox can only be used with AnalysisBoardModel";
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
    
    public function asComponent():Component
    {
        return this;
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

    private function treeProcessWheel(tree:VariationTree, e:MouseEvent)
    {
        if (e.ctrlKey) 
        {
            e.cancel();
            if (e.delta > 0 && tree.scale < 8)
                tree.setScale(tree.scale * 2);
            else if (e.delta < 0 && tree.scale > 0.125)
                tree.setScale(tree.scale / 2);
        } 
    }

    private function refreshVariationView()
    {
        variationViewSV.removeAllComponents();
        variationViewSV.unregisterEvent(MouseEvent.MOUSE_WHEEL, activeWheelHandler);

        switch Preferences.branchingTabType.get() 
        {
            case Tree:
                var tree:VariationTree = new VariationTree();
                activeWheelHandler = treeProcessWheel.bind(tree);
                variationViewSV.registerEvent(MouseEvent.MOUSE_WHEEL, activeWheelHandler, 100);

                variationView = tree;
            case Outline:
                variationView = new VariationOutline();
            case PlainText:
                variationView = new VariationPlainText();
        }

        variationViewSV.addComponent(variationView.asComponent());
        variationView.init(analysisModel, eventHandler);
    }

    @:bind(branchingHelpLink, MouseEvent.CLICK)
    private function onBranchingHelpClicked(e)
    {
        Dialogs.getQueue().addBasic(new BranchingHelp(), null, true);
    }

    public function new()
    {
        super();
    }
}