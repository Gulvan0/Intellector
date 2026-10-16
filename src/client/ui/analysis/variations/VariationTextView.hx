package client.ui.analysis.variations;

import client.datatypes.variations.PlyTreeNode;
import client.formatters.VariationFormatters;
import client.logic.variations.PlainTextBlocks;
import client.logic.variations.PlainTextBlocks.PlainTextBlock;
import haxe.ui.Toolkit;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.ContinuousHBox;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import js.Browser;
import js.html.Element;

using client.ui.ComponentExtension;

/**
    The variations as wrapping text: a block runs until the tree branches, and each branch starts a
    block one level in, joined to its parent by a rail with an elbow.
**/
class VariationTextView extends Box
{
    private static inline final BASE_INDENT:Int = 12;
    private static inline final LEVEL_INDENT:Int = 18;
    private static inline final RAIL_OFFSET:Int = 6;
    private static inline final RAIL_WIDTH:Int = 2;
    private static inline final ELBOW_WIDTH:Int = 8;
    // the elbow's height in a block: its vertical padding plus half a token
    private static inline final ELBOW_Y:Int = 17;
    private static inline final RAIL_COLOR:String = "#bdb2a0";
    private static inline final LINE_RAIL_COLOR:String = "#c79a56";

    private final onSelect:PlyTreeNode->Void;
    private final list:VBox;
    private final scroller:NativeScroller;

    private var selected:Null<PlyTreeNode> = null;
    private var tokensByNode:Map<PlyTreeNode, HBox> = [];
    private var blocks:Array<{block:PlainTextBlock, rails:Element}> = [];

    public function new(onSelect:PlyTreeNode->Void)
    {
        super();
        this.onSelect = onSelect;
        percentWidth = 100;
        percentHeight = 100;

        list = new VBox();
        list.percentWidth = 100;
        list.addClass(StyleClass.VARIATION_TEXT_LIST);

        scroller = new NativeScroller(list, false);
        addComponent(scroller);
    }

    public function showTree(root:PlyTreeNode, selected:PlyTreeNode):Void
    {
        this.selected = selected;
        list.removeAllComponents();
        tokensByNode = [];
        blocks = [];

        for (block in PlainTextBlocks.layout(root))
            list.addComponent(createBlock(block));

        restyle();
    }

    public function select(selected:PlyTreeNode):Void
    {
        this.selected = selected;
        restyle();
    }

    private function createBlock(block:PlainTextBlock):Box
    {
        var row:ContinuousHBox = new ContinuousHBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.VARIATION_TEXT_BLOCK);
        row.paddingLeft = BASE_INDENT + block.depth * LEVEL_INDENT;

        for (node in block.nodes)
        {
            var token:HBox = createToken(node);
            tokensByNode.set(node, token);
            row.addComponent(token);
        }

        // HaxeUI rewrites the block's own background, so the rails live in a layer of their own beneath the tokens
        var rails:Element = Browser.document.createDivElement();
        rails.style.position = "absolute";
        rails.style.setProperty("inset", "0");
        rails.style.pointerEvents = "none";
        row.element.insertBefore(rails, row.element.firstChild);
        blocks.push({block: block, rails: rails});

        return row;
    }

    private function createToken(node:PlyTreeNode):HBox
    {
        var token:HBox = new HBox();
        token.addClass(StyleClass.VARIATION_TOKEN);
        token.trackHover();
        token.onClick = _ -> onSelect(node);

        var text:Label = new Label();
        text.verticalAlign = "center";
        text.addClass(StyleClass.VARIATION_TOKEN_TEXT);

        if (node.isRoot())
        {
            token.addClass(StyleClass.VARIATION_TOKEN_ROOT);
            text.text = LocaleUtils.localeBinding("intellector.analysis.variations.root");
        }
        else
        {
            var number:Label = new Label();
            number.text = Std.string(node.depth);
            number.verticalAlign = "center";
            number.addClass(StyleClass.VARIATION_TOKEN_NUMBER);
            token.addComponent(number);
            token.addComponent(VariationDisc.create(node.moverColor()));
            text.text = VariationFormatters.notation(node);
        }

        token.addComponent(text);
        return token;
    }

    private function restyle():Void
    {
        var onLine:Map<PlyTreeNode, Bool> = [];
        if (selected != null)
            for (node in selected.line())
                onLine.set(node, true);

        for (node => token in tokensByNode)
        {
            token.setClass(StyleClass.VARIATION_TOKEN_SELECTED, node == selected);
            token.setClass(StyleClass.VARIATION_TOKEN_OFF_LINE, node != selected && !onLine.exists(node));
        }

        for (entry in blocks)
            entry.rails.style.background = railsBackground(entry.block, onLine.exists(entry.block.nodes[0]));

        revealSelected();
    }

    private function railsBackground(block:PlainTextBlock, onLine:Bool):String
    {
        var layers:Array<String> = [];
        if (block.depth >= 1)
        {
            var x:Int = BASE_INDENT + (block.depth - 1) * LEVEL_INDENT + RAIL_OFFSET;
            var color:String = onLine ? LINE_RAIL_COLOR : RAIL_COLOR;
            layers.push(layer(color, x, 0, '${RAIL_WIDTH}px', '${ELBOW_Y + 1}px'));
            layers.push(layer(color, x, ELBOW_Y - 1, '${ELBOW_WIDTH}px', '${RAIL_WIDTH}px'));
            if (!block.isLastSibling)
                layers.push(layer(RAIL_COLOR, x, 0, '${RAIL_WIDTH}px', "100%"));
        }
        for (level in 0...block.railsPassing.length)
            if (block.railsPassing[level])
                layers.push(layer(RAIL_COLOR, BASE_INDENT + level * LEVEL_INDENT + RAIL_OFFSET, 0, '${RAIL_WIDTH}px', "100%"));

        return layers.length > 0 ? layers.join(",") : "none";
    }

    private static function layer(color:String, x:Int, y:Int, width:String, height:String):String
    {
        return 'linear-gradient($color, $color) ${x}px ${y}px / $width $height no-repeat';
    }

    private function revealSelected():Void
    {
        var token:Null<HBox> = selected != null ? tokensByNode.get(selected) : null;
        if (token == null)
            return;

        Toolkit.callLater(() -> {
            var viewport:Element = scroller.element;
            var viewportRect:js.html.DOMRect = viewport.getBoundingClientRect();
            var tokenRect:js.html.DOMRect = token.element.getBoundingClientRect();
            if (tokenRect.top < viewportRect.top)
                viewport.scrollTop -= Math.ceil(viewportRect.top - tokenRect.top);
            else if (tokenRect.bottom > viewportRect.bottom)
                viewport.scrollTop += Math.ceil(tokenRect.bottom - viewportRect.bottom);
        });
    }
}
