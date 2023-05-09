package gfx.game.analysis;

import gfx.game.interfaces.IReadOnlyAnalysisBoardModel;
import net.shared.variation.ReadOnlyVariationNode;
import net.shared.variation.VariationMap;
import net.shared.variation.VariationPath;
import net.shared.variation.ReadOnlyVariation;
import gfx.game.events.VariationViewEvent;
import gfx.game.analysis.variation_plain_text.NodeInfo;
import gfx.game.analysis.variation_plain_text.PlyNode;
import gfx.game.analysis.variation_plain_text.Item;
import net.shared.utils.MathUtils;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import haxe.ui.core.Component;
import haxe.ui.components.Label;
import gfx.utils.PlyScrollType;
import haxe.ui.styles.Style;
import haxe.ui.components.Link;
import haxe.ui.containers.HBox;

class VariationPlainText extends HBox implements IVariationView
{
    private var DEFAULT_STYLE:Style = {color: 0x333333, fontUnderline: false};

    private var selectedNode:Null<PlyNode> = null;
    private var hasLeadingDots:Bool;

    private var eventHandler:VariationViewEvent->Void;

    private var nodes:VariationMap<NodeInfo> = new VariationMap();
    private var items:Array<Item> = [];

    public function init(model:IReadOnlyAnalysisBoardModel, eventHandler:VariationViewEvent->Void)
    {
        this.eventHandler = eventHandler;

        updateVariation(model.getVariation(), model.getSelectedNodePath(), model.getSelectedBranch());
    }

    public function updateVariation(variation:ReadOnlyVariation, selectedNodePath:VariationPath, fullSelectedBranch:VariationPath)
    {
        removeAllComponents();

        hasLeadingDots = variation.rootNode().getSituation().turnColor == Black;
        if (hasLeadingDots)
            addComponent(label("..."));

        selectedNode = null;

        nodes = new VariationMap();
        items = [];

        for (variationNode in variation.depthFirst(false))
            addChildNode(variationNode, variationNode.getIncomingPly());

        pack();

        updateSelectedNode(selectedNodePath, fullSelectedBranch);
    }

    public function updateSelectedNode(selectedNodePath:VariationPath, fullSelectedBranch:VariationPath)
    {
        if (selectedNode != null)
            selectedNode.selected = false;

        if (selectedNodePath.isRoot())
            selectedNode = null;
        else
        {
            selectedNode = nodes.get(selectedNodePath).node;
            selectedNode.selected = true;
        }
    }

    public function asComponent():Component
    {
        return this;
    }

    private function onNodeSelectRequest(path:VariationPath)
    {
        eventHandler(NodeSelected(path));
    }

    private function onNodeRemovalRequest(path:VariationPath)
    {
        eventHandler(NodeRemoved(path));
    }

    /**
        Prevents the occurence of the lone brackets due to the line break by combining each of them with the nearest node into a single (non-continuous) HBox.
        May only be called once. Breaks the connection between the child components and `items` array.
    **/
    private function pack()
    {
        #if test_var_plain_text
        trace("Before pack(): ");
        for (child in childComponents)
            if (Std.isOfType(child, HBox))
            {
                trace("HBox [");
                for (c in cast(child, HBox).childComponents)
                    if (Std.isOfType(c, PlyNode))
                        trace('PlyNode: ${cast(c, PlyNode).text}');
                    else if (Std.isOfType(c, Label))
                        trace('Label: ${cast(c, Label).text}');
                    else
                        trace('Unknown: ${Type.getClassName(Type.getClass(c))}');
                trace("]");
            }
            else if (Std.isOfType(child, PlyNode))
                trace('PlyNode: ${cast(child, PlyNode).text}');
            else if (Std.isOfType(child, Label))
                trace('Label: ${cast(child, Label).text}');
            else
                trace('Unknown: ${Type.getClassName(Type.getClass(child))}');
        trace("-------");
        #end

        var itemsIndex:Int = 0;
        var childIndex:Int = hasLeadingDots? 1 : 0;
        
        var itemsLength:Int = items.length;

        var lastHBox:HBox = null;
        var lastNode:PlyNode = null;
        var rbracesLabelText:String = "";

        while (itemsIndex <= itemsLength)
        {
            var currentItem:Item = items[itemsIndex];

            if (rbracesLabelText != "" && (itemsIndex == itemsLength || !currentItem.match(RBrace(_, _))))
            {
                var combinedLabel:Label = label(rbracesLabelText);

                if (lastHBox != null)
                    lastHBox.addComponent(combinedLabel);
                else
                {
                    removeComponent(lastNode, false);

                    var hbox:HBox = new HBox();
                    hbox.verticalAlign = 'center';
                    hbox.customStyle = {horizontalSpacing: 0};
                    hbox.addComponent(lastNode);
                    hbox.addComponent(combinedLabel);
                    addComponentAt(hbox, childIndex - 1);
                    lastNode.validateComponentStyle();
                }

                rbracesLabelText = "";
            }

            if (itemsIndex == itemsLength)
                break;

            switch currentItem
            {
                case LBrace(label):
                    var braceOwner:Component = getComponentAt(childIndex + 1);

                    removeComponent(label, false);
                    removeComponent(braceOwner, false);

                    var hbox:HBox = new HBox();
                    hbox.verticalAlign = 'center';
                    hbox.customStyle = {horizontalSpacing: 0};
                    hbox.addComponent(label);
                    hbox.addComponent(braceOwner);
                    addComponentAt(hbox, childIndex);
                    braceOwner.validateComponentStyle();

                    lastHBox = hbox;
                    lastNode = null;

                    childIndex++;
                    itemsIndex += 2;
                case RBrace(label, ownerInfo):
                    removeComponent(label);
                    rbracesLabelText += ")";

                    itemsIndex++;
                case Node(info):
                    lastHBox = null;
                    lastNode = info.node;

                    childIndex++;
                    itemsIndex++;
            }
        }

        #if test_var_plain_text
        trace("After pack(): ");
        for (child in childComponents)
            if (Std.isOfType(child, HBox))
            {
                trace("HBox [");
                for (c in cast(child, HBox).childComponents)
                    if (Std.isOfType(c, PlyNode))
                        trace('PlyNode: ${cast(c, PlyNode).text}');
                    else if (Std.isOfType(c, Label))
                        trace('Label: ${cast(c, Label).text}');
                    else
                        trace('Unknown: ${Type.getClassName(Type.getClass(c))}');
                trace("]");
            }
            else if (Std.isOfType(child, PlyNode))
                trace('PlyNode: ${cast(child, PlyNode).text}');
            else if (Std.isOfType(child, Label))
                trace('Label: ${cast(child, Label).text}');
            else
                trace('Unknown: ${Type.getClassName(Type.getClass(child))}');
        trace("----------------------------");
        #end
    }

    private function updateIndexes(start:Int)
    {
        for (i in start...items.length)
            switch items[i] 
            {
                case Node(info):
                    info.index = i;
                case RBrace(_, ownerInfo):
                    ownerInfo.rbraceIndex = i;
                default:
            }
    }

    private function insertNode(info:NodeInfo, at:Int, ?hasBraces:Bool = false) 
    {
        var shift:Int = hasLeadingDots? 1 : 0;
        
        if (hasBraces)
        {
            var lbrace:Label = label("(");
            var rbrace:Label = label(")");

            info.index = at + 1;
            info.rbraceIndex = at + 2;

            addComponentAt(lbrace, shift + at);
            addComponentAt(info.node, shift + at + 1);
            addComponentAt(rbrace, shift + at + 2);

            items.insert(at, LBrace(lbrace));
            items.insert(at + 1, Node(info));
            items.insert(at + 2, RBrace(rbrace, info));

            updateIndexes(at + 3);
        }
        else
        {
            info.index = at;
            addComponentAt(info.node, shift + at);
            items.insert(at, Node(info));
            updateIndexes(at + 1);
        }
    }

    public function addChildNode(node:ReadOnlyVariationNode, ply:RawPly)
    {
        var path:VariationPath = node.getPath();
        var parentPath:VariationPath = path.parentPath();
        var nodeNum:Int = node.getChildNum();

        var plyNodeText:String = path.length + ". " + node.getIncomingPlyStr(false);
        var plyNode:PlyNode = new PlyNode(path, plyNodeText, onNodeSelectRequest, onNodeRemovalRequest, DEFAULT_STYLE);
        var nodeInfo:NodeInfo = {node: plyNode, index: -1};
        nodes.set(path, nodeInfo);

        if (nodeNum > 0)
        {
            var leftSiblingPath:VariationPath = node.leftSibling().getPath();
            var leftSiblingInfo:NodeInfo = nodes.get(leftSiblingPath);

            if (leftSiblingInfo.rbraceIndex != null)
                insertNode(nodeInfo, leftSiblingInfo.rbraceIndex + 1, true);
            else
                insertNode(nodeInfo, leftSiblingInfo.index + 1, true);
        }
        else if (path.length == 1)
            insertNode(nodeInfo, 0);
        else
        {
            var parent:ReadOnlyVariationNode = node.getParent();
            var grandparent:ReadOnlyVariationNode = parent.getParent();
            var youngestAunt:ReadOnlyVariationNode = grandparent.getLastChild();

            var parentIsFirstborn:Bool = parent.getChildNum() == 0;
            var parentHasSiblings:Bool = grandparent.childCount() > 1;

            var insertAt:Int;
            if (parentHasSiblings && parentIsFirstborn)
                insertAt = nodes.get(youngestAunt.getPath()).rbraceIndex + 1;
            else
                insertAt = nodes.get(parent.getPath()).index + 1;

            insertNode(nodeInfo, insertAt);
        }
    }

    public function new()
    {
        super();
        this.continuous = true;
    }

    private function label(text:String):Label
    {
        var b:Label = new Label();
        b.text = text;
        b.verticalAlign = 'center';
        b.customStyle = DEFAULT_STYLE;
        return b;
    }
}