package gfx.game.analysis;

import gfx.game.analysis.variation_tree.util.DisplacementInfo;
import net.shared.variation.Variation;
import gfx.game.analysis.variation_tree.Arrow;
import gfx.game.analysis.variation_tree.Node;
import gfx.game.models.AnalysisBoardModel;
import net.shared.variation.ReadOnlyVariation;
import net.shared.variation.VariationPath;
import net.shared.variation.VariationMap;
import gfx.game.events.VariationViewEvent;
import haxe.ui.containers.Box;
import haxe.ui.containers.Absolute;
import net.shared.board.RawPly;
import net.shared.utils.MathUtils;
import net.shared.board.Situation;
import haxe.ui.events.MouseEvent;
import gfx.utils.PlyScrollType;
import haxe.ui.core.Component;
import haxe.ds.ArraySort;
import haxe.Timer;
import dict.Dictionary;
import haxe.ui.components.Link;

class VariationTree extends Absolute implements IVariationView
{
    private static var NORMAL_BLOCK_INTERVAL_X:Float = 15;
    private static var NORMAL_PERIOD_Y:Float = 50;

    public var scale(default, null):Float = 1;

    private var arrows:VariationMap<Arrow> = new VariationMap();
    private var nodes:VariationMap<Node> = new VariationMap();

    private var selectedNodePath:VariationPath;
    private var fullSelectedBranch:VariationPath;

    private var variation:ReadOnlyVariation;
    private var eventHandler:VariationViewEvent->Void;
    
    private function columnX(column:Int, columnWidths:Map<Int, Float>):Float
    {
        var s:Float = 0;
        for (i in 1...column)
            s += columnWidths.get(i) + NORMAL_BLOCK_INTERVAL_X * scale;
        return s;
    }

    private function rowY(row:Int):Float
    {
        return row * NORMAL_PERIOD_Y * scale;
    }

    private function clear(eraseSelectedNodeData:Bool)
    {
        removeAllComponents();

        if (eraseSelectedNodeData)
        {
            this.selectedNodePath = null;
            this.fullSelectedBranch = null;
        }

        this.arrows = new VariationMap();
        this.nodes = new VariationMap();
    }

    public function init(model:AnalysisBoardModel, eventHandler:VariationViewEvent->Void)
    {
        this.eventHandler = eventHandler;
        this.variation = model.getVariation();

        drawFromScratch();
        updateSelectedNode(model.getSelectedNodePath(), model.getSelectedBranch());
        refreshLayout();
    }

    public function updateVariation(variation:ReadOnlyVariation, selectedNodePath:VariationPath, fullSelectedBranch:VariationPath)
    {
        clear(true);

        this.variation = variation;

        drawFromScratch();
        updateSelectedNode(selectedNodePath, fullSelectedBranch);
        refreshLayout();
    }
    
    public function updateSelectedNode(selectedNodePath:VariationPath, fullSelectedBranch:VariationPath)
    {
        if (this.selectedNodePath != null)
            nodes.get(this.selectedNodePath).deselect();
        if (this.fullSelectedBranch != null)
            for (path in this.fullSelectedBranch.ancestorPathsIterator(true))
                arrows.get(path).unhighlight();

        this.selectedNodePath = selectedNodePath;
        this.fullSelectedBranch = fullSelectedBranch;

        nodes.get(selectedNodePath).select();

        for (path in fullSelectedBranch.ancestorPathsIterator(true))
        {
            var arrow:Arrow = arrows.get(path);
            var node:Node = nodes.get(path);

            if (path.length > selectedNodePath.length)
                arrow.highlight(false);
            else if (path.length > 0)
                arrow.highlight(true);

            arrow.moveComponentToFront();
            node.moveComponentToFront();
        }
    }
    
    public function asComponent():Component
    {
        return this;
    }

    public function refreshLayout()
    {
        var displacement:DisplacementInfo = buildOptimalDisplacement();
        
        //Calculate column widths
        var columnWidths:Map<Int, Float> = [];
        for (column => paths in displacement.columnContents.keyValueIterator())
        {
            var maxWidth:Float = column == 1? nodes.get(VariationPath.root()).textSize.width : 0;
            for (path in paths)
            {
                var node = nodes.get(path);
                if (node.textSize.width > maxWidth)
                    maxWidth = node.textSize.width;
            }
            columnWidths.set(column, maxWidth);
        }
        
        //Update nodes
        for (path => cell in displacement.cellularMapping.keyValueIterator())
        {
            var node:Node = nodes.get(path);
            node.left = columnX(cell.column, columnWidths);
            node.top = rowY(cell.row);
            node.width = columnWidths.get(cell.column);
            node.path = path;
        }

        //Update arrows
        for (path => arrow in arrows.keyValueIterator())
        {
            var parentPath = path.parentPath();
            var departure = nodes.get(parentPath).outputPos();
            var destination = nodes.get(path).inputPos();
            arrow.changeEndpoints(departure, destination);
        }
    }

    private function buildOptimalDisplacement():DisplacementInfo
    {
        var info:DisplacementInfo = new DisplacementInfo();

        var rowLengths:Map<Int, Int> = [];

        for (variationNode in variation.depthFirst(false))
        {
            var path:VariationPath = variationNode.getPath();
            var row:Int = path.length;
            var parentPath:String = path.parentPath();

            var maxDescendantRowLength:Int = 0;
            for (mainlineDescendant in variation.getMainlineDescendants(false))
                maxDescendantRowLength = MathUtils.maxInt(maxDescendantRowLength, rowLengths.get(iteratedRow));

            var column:Int = MathUtils.maxInt(maxDescendantRowLength + 1, info.cellularMapping.get(parentPath).column);

            rowLengths[row] = column;

            info.addCell(path, row, column);
        }
        
        return info;
    }

    public function setScale(scale:Float)
    {
        clear(false);

        this.scale = scale;

        drawFromScratch();
        updateSelectedNode(selectedNodePath, fullSelectedBranch);
        refreshLayout();
    }

    private function onNodeSelectRequested(path:VariationPath)
    {
        eventHandler(NodeSelected(path));
    }

    private function onNodeRemovalRequested(path:VariationPath)
    {
        eventHandler(NodeRemoved(path));
    }

    private function drawFromScratch()
    {
        var indicateColors:Bool = Preferences.branchingTurnColorIndicators.get();

        var startingNode:Node = new Node(scale, VariationPath.root(), Dictionary.getPhrase(OPENING_STARTING_POSITION), false, onNodeSelectRequested, onNodeRemovalRequested);
        nodes.set(VariationPath.root(), startingNode);
        addComponent(startingNode);

        for (variationNode in variation.depthFirst(false))
        {
            var node = new Node(scale, variationNode.getPath(), variationNode.getIncomingPlyStr(indicateColors), false, onNodeSelectRequested, onNodeRemovalRequested);
            var arrow = new Arrow(scale);

            nodes.set(code, node);
            arrows.set(code, arrow);

            addComponent(node);
            addComponent(arrow);
            arrow.moveComponentToBack();
        }
    }

    public function new() 
    {
        super();
    }
}