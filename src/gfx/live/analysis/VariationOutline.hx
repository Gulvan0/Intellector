package gfx.live.analysis;

import net.shared.variation.Variation;
import gfx.live.events.VariationViewEvent;
import gfx.live.models.AnalysisBoardModel;
import net.shared.variation.ReadOnlyVariation;
import net.shared.variation.VariationPath;
import haxe.ui.core.Component;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import haxe.Timer;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import haxe.ui.containers.TreeViewNode;
import gfx.utils.PlyScrollType;
import haxe.ui.containers.TreeView;

class VariationOutline extends TreeView implements IVariationView 
{
    private var rootNode:TreeViewNode;

    private var eventHandler:VariationViewEvent->Void;

    public function init(model:AnalysisBoardModel, eventHandler:VariationViewEvent->Void)
    {
        this.eventHandler = eventHandler;

        rootNode = addNode({text: Dictionary.getPhrase(OPENING_STARTING_POSITION)});
        rootNode.onClick = e -> {Timer.delay(onNodeChanged.bind(rootNode), 50);};

        updateVariation(model.getVariation(), model.getSelectedNodePath(), model.getSelectedBranch());
    }

    public function updateVariation(variation:ReadOnlyVariation, selectedNodePath:VariationPath, fullSelectedBranch:VariationPath)
    {
        rootNode.clearNodes();

        for (variationNode in variation.depthFirst(false))
        {
            var text:String = variationNode.getIncomingPlyStr(false);
            var childPath:VariationPath = variationNode.getPath();
            var childNum:Int = variationNode.getChildNum();

            var childNode:TreeViewNode = parentNode.addNode({text: text, nodeId: '$childNum'});
            childNode.expanded = true;
            childNode.onClick = onNodeClicked.bind(childNode, childPath);
        }

        updateSelectedNode(selectedNodePath, fullSelectedBranch);
    }

    public function updateSelectedNode(selectedNodePath:VariationPath, fullSelectedBranch:VariationPath)
    {
        if (!selectedNodePath.isRoot())
        {
            var selectedPathStr:String = selectedNodePath.asArray().join('/');
            rootNode.findNodeByPath(selectedPathStr).selected = true;
        }
        else 
            rootNode.selected = true;
    }

    public function asComponent():Component
    {
        return this;
    }

    public function new()
    {
        super();
    }

    private function onNodeChanged(treeNode:TreeViewNode, path:VariationPath)
    {
        if (treeNode.selected)
            eventHandler(NodeSelected(path));
    }

    private var stopClickCapture:Bool = false;

    private function onNodeClicked(treeNode:TreeViewNode, path:VariationPath, e:MouseEvent)
    {
        if (stopClickCapture)
            return;

        stopClickCapture = true;

        if (e.ctrlKey)
            eventHandler(NodeRemoved(path));
        else
            Timer.delay(onNodeChanged.bind(treeNode, path), 50);

        Timer.delay(() -> {stopClickCapture = false;}, 20);
    }
}