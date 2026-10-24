package client.ui.analysis.variations;

import client.datatypes.variations.PlyTreeNode;
import client.formatters.VariationFormatters;
import client.logic.variations.TreeGrid;
import client.logic.variations.TreeGrid.TreeCell;
import haxe.ui.Toolkit;
import haxe.ui.components.Label;
import haxe.ui.containers.Absolute;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/**
    The variations as a grid: a row per ply, a column per branch, edges from each move to its
    continuations. Laid out at 100% and scaled as a whole; the row numbers stay in view horizontally.
**/
class VariationTreeView extends Box
{
    public static final ZOOM_STEPS:Array<Float> = [0.6, 0.8, 1, 1.25, 1.5];
    public static inline final MIN_SCALE:Float = 0.5;
    public static inline final MAX_SCALE:Float = 2;

    private static inline final ROW_HEIGHT:Float = 44;
    private static inline final PILL_HEIGHT:Float = 28;
    private static inline final PILL_TOP:Float = 8;
    private static inline final TOP_OFFSET:Float = 6;
    private static inline final GUTTER_WIDTH:Float = 30;
    private static inline final LEFT_PADDING:Float = 10;
    private static inline final COLUMN_GAP:Float = 14;
    private static inline final ROOT_WIDTH:Float = 150; // fits the longest localized label
    private static inline final MIN_COLUMN_WIDTH:Float = 40;
    // the notation font's advance, plus the pill's padding and colour disc
    private static inline final CHARACTER_WIDTH:Float = 8.4;
    private static inline final PILL_EXTRA_WIDTH:Float = 36;
    private static inline final RIGHT_PADDING:Float = 14;
    private static inline final BOTTOM_PADDING:Float = 56; // unscaled: clears the tools over the view's bottom at any zoom
    private static inline final EDGE_WIDTH:Float = 2;
    private static inline final PREVIEW_BADGE_SIZE:Float = 16;

    /** Called with the new scale whenever it changes **/
    public var onScaleChanged:Float->Void = _ -> {};

    private final onSelect:PlyTreeNode->Void;
    private final scroller:NativeScroller;
    private final sizer:Absolute;
    private final canvas:Absolute;
    private final gutter:Absolute;
    private final gutterRail:Box;
    private final previewBadge:PreviewBadge;

    private var root:Null<PlyTreeNode> = null;
    private var selected:Null<PlyTreeNode> = null;
    private var previewNode:Null<PlyTreeNode> = null;
    private var cells:Array<TreeCell> = [];
    private var cellsByNode:Map<PlyTreeNode, TreeCell> = [];
    private var pillsByNode:Map<PlyTreeNode, Box> = [];
    private var rowNumbers:Array<Label> = []; // rowNumbers[i]: row i + 1's
    private var edges:Array<Box> = [];
    private var columnX:Array<Float> = [];
    private var columnWidths:Array<Float> = [];
    private var contentWidth:Float = 0;
    private var contentHeight:Float = 0;
    private var scale:Float = 1;

    public function new(onSelect:PlyTreeNode->Void)
    {
        super();
        this.onSelect = onSelect;
        percentWidth = 100;
        percentHeight = 100;

        canvas = new Absolute();
        canvas.addClass(StyleClass.VARIATION_TREE_CANVAS);
        canvas.element.style.transformOrigin = "0 0";

        gutter = new Absolute();
        gutter.addClass(StyleClass.VARIATION_TREE_GUTTER);
        gutter.element.style.zIndex = "2"; // over the pills and the badge scrolled under it, including ones added later
        canvas.addComponent(gutter);

        previewBadge = new PreviewBadge(false);
        previewBadge.width = PREVIEW_BADGE_SIZE;
        previewBadge.height = PREVIEW_BADGE_SIZE;
        previewBadge.element.style.zIndex = "1"; // over the pills added after it
        previewBadge.hidden = true;
        canvas.addComponent(previewBadge);

        sizer = new Absolute();
        sizer.addClass(StyleClass.VARIATION_TREE_CANVAS);
        sizer.addComponent(canvas);

        gutterRail = new Box(); // continues the gutter below the content, down to the view's bottom
        gutterRail.percentHeight = 100;
        gutterRail.addClass(StyleClass.VARIATION_TREE_GUTTER);
        addComponent(gutterRail);

        scroller = new NativeScroller(sizer, true);
        scroller.element.style.setProperty("touch-action", "pan-x pan-y");
        scroller.addClass(StyleClass.VARIATION_TREE_SCROLLER);
        scroller.element.addEventListener("scroll", keepGutterInView);
        addComponent(scroller);

        new ZoomGestures(scroller.element, (factor, clientX, clientY) -> {
            var rect:js.html.DOMRect = scroller.element.getBoundingClientRect();
            zoomAround(scale * factor, clientX - rect.left, clientY - rect.top);
        });
        new DragPanning(scroller.element, setPanning);
    }

    public function getScale():Float
    {
        return scale;
    }

    public function showTree(root:PlyTreeNode, selected:PlyTreeNode):Void
    {
        this.root = root;
        this.selected = selected;
        rebuild();
        revealSelected();
    }

    public function select(selected:PlyTreeNode):Void
    {
        this.selected = selected;
        restyleNodes();
        rebuildEdges();
        revealSelected();
    }

    /** Marks `node` as the card preview, `auto` while it's that by default; null for no mark **/
    public function setCardPreview(node:Null<PlyTreeNode>, auto:Bool):Void
    {
        previewNode = node;
        previewBadge.setAuto(auto);
        placePreviewBadge();
    }

    /** Zooms keeping the viewport's centre in place **/
    public function setScale(newScale:Float):Void
    {
        zoomAround(newScale, scroller.element.clientWidth / 2, scroller.element.clientHeight / 2);
    }

    public function zoomIn():Void
    {
        for (step in ZOOM_STEPS)
            if (step > scale + 0.001)
            {
                setScale(step);
                return;
            }
    }

    public function zoomOut():Void
    {
        var target:Null<Float> = null;
        for (step in ZOOM_STEPS)
            if (step < scale - 0.001)
                target = step;
        if (target != null)
            setScale(target);
    }

    // keeps the content point at (`viewportX`, `viewportY`) under the same viewport point
    private function zoomAround(newScale:Float, viewportX:Float, viewportY:Float):Void
    {
        newScale = Math.max(MIN_SCALE, Math.min(MAX_SCALE, newScale));
        if (Math.abs(newScale - scale) < 0.0001)
            return;

        var element:js.html.Element = scroller.element;
        var contentX:Float = (element.scrollLeft + viewportX) / scale;
        var contentY:Float = (element.scrollTop + viewportY) / scale;

        scale = newScale;
        applyScale();
        element.scrollLeft = Math.round(contentX * scale - viewportX);
        element.scrollTop = Math.round(contentY * scale - viewportY);
        keepGutterInView();
        onScaleChanged(scale);
    }

    private function applyScale():Void
    {
        canvas.element.style.transform = 'scale($scale)';
        gutterRail.width = GUTTER_WIDTH * scale;
        sizer.width = Math.ceil(contentWidth * scale);
        sizer.height = Math.ceil((contentHeight - BOTTOM_PADDING) * scale + BOTTOM_PADDING);
        // HaxeUI sizes the DOM later; the scroll offsets set right after need the extent now
        sizer.element.style.width = sizer.width + "px";
        sizer.element.style.height = sizer.height + "px";
    }

    private function keepGutterInView(?_:Dynamic):Void
    {
        gutter.element.style.transform = 'translateX(${scroller.element.scrollLeft / scale}px)';
    }

    private function setPanning(panning:Bool):Void
    {
        scroller.setClass(StyleClass.VARIATION_TREE_PANNING, panning);
        scroller.element.style.cursor = panning ? "grabbing" : "grab"; // HaxeUI applies the class's cursor only on its next validation
    }

    // keeps the pills of the nodes still in the tree and the row numbers still needed: creating them is the expensive part
    private function rebuild():Void
    {
        cellsByNode = [];
        cells = TreeGrid.layout(root);
        var maxRow:Int = 0;
        var maxColumn:Int = 0;
        for (cell in cells)
        {
            cellsByNode.set(cell.node, cell);
            maxRow = Std.int(Math.max(maxRow, cell.row));
            maxColumn = Std.int(Math.max(maxColumn, cell.column));
        }

        columnWidths = [for (_ in 0...maxColumn + 1) MIN_COLUMN_WIDTH];
        for (cell in cells)
            if (!cell.node.isRoot())
                columnWidths[cell.column] = Math.max(columnWidths[cell.column], Math.ceil(VariationFormatters.notation(cell.node).length * CHARACTER_WIDTH) + PILL_EXTRA_WIDTH);

        columnX = [];
        var x:Float = GUTTER_WIDTH + LEFT_PADDING;
        for (width in columnWidths)
        {
            columnX.push(x);
            x += width + COLUMN_GAP;
        }

        contentWidth = Math.max(x - COLUMN_GAP + RIGHT_PADDING, columnX[0] + ROOT_WIDTH + RIGHT_PADDING);
        contentHeight = TOP_OFFSET + (maxRow + 1) * ROW_HEIGHT + BOTTOM_PADDING;
        canvas.width = contentWidth;
        canvas.height = contentHeight;

        var stalePills:Map<PlyTreeNode, Box> = pillsByNode;
        pillsByNode = [];
        for (cell in cells)
        {
            var pill:Null<Box> = stalePills.get(cell.node);
            if (pill == null)
            {
                pill = createPill(cell.node);
                canvas.addComponent(pill);
            }
            else
                stalePills.remove(cell.node);
            placePill(pill, cell);
            pillsByNode.set(cell.node, pill);
        }
        for (pill in stalePills)
            canvas.removeComponent(pill);

        gutter.width = GUTTER_WIDTH;
        gutter.height = contentHeight;
        while (rowNumbers.length > maxRow)
            gutter.removeComponent(rowNumbers.pop());
        for (row in rowNumbers.length + 1...maxRow + 1)
        {
            var number:Label = new Label();
            number.text = Std.string(row);
            number.addClass(StyleClass.VARIATION_TREE_ROW_NUMBER);
            number.left = 0;
            number.top = TOP_OFFSET + row * ROW_HEIGHT;
            number.width = GUTTER_WIDTH;
            number.height = ROW_HEIGHT;
            gutter.addComponent(number);
            rowNumbers.push(number);
        }

        restyleNodes();
        rebuildEdges();
        placePreviewBadge();
        applyScale();
        keepGutterInView();
    }

    // centred on the pill's top right corner
    private function placePreviewBadge():Void
    {
        var cell:Null<TreeCell> = previewNode != null ? cellsByNode.get(previewNode) : null;
        previewBadge.hidden = cell == null;
        if (cell == null)
            return;

        var pillWidth:Float = cell.node.isRoot() ? ROOT_WIDTH : columnWidths[cell.column];
        previewBadge.left = columnX[cell.column] + pillWidth - PREVIEW_BADGE_SIZE / 2;
        previewBadge.top = TOP_OFFSET + cell.row * ROW_HEIGHT + PILL_TOP - PREVIEW_BADGE_SIZE / 2 + 1;
    }

    private function placePill(pill:Box, cell:TreeCell):Void
    {
        pill.left = columnX[cell.column];
        pill.top = TOP_OFFSET + cell.row * ROW_HEIGHT + PILL_TOP;
        pill.width = cell.node.isRoot() ? ROOT_WIDTH : columnWidths[cell.column];
    }

    private function createPill(node:PlyTreeNode):Box
    {
        var pill:Box = new Box();
        pill.addClass(StyleClass.VARIATION_NODE);
        pill.height = PILL_HEIGHT;
        pill.onClick = _ -> onSelect(node);
        pill.trackHover();

        var content:HBox = new HBox();
        content.addClass(StyleClass.VARIATION_NODE_CONTENT);
        content.horizontalAlign = "center";
        content.verticalAlign = "center";

        var text:Label = new Label();
        text.verticalAlign = "center";
        if (node.isRoot())
        {
            pill.addClass(StyleClass.VARIATION_NODE_ROOT);
            text.text = LocaleUtils.localeBinding("intellector.analysis.variations.root");
        }
        else
        {
            content.addComponent(VariationDisc.create(node.moverColor()));
            text.text = VariationFormatters.notation(node);
        }
        text.addClass(StyleClass.VARIATION_NODE_TEXT);
        content.addComponent(text);
        pill.addComponent(content);
        return pill;
    }

    private function restyleNodes():Void
    {
        var onLine:Map<PlyTreeNode, Bool> = lineSet();
        for (node => pill in pillsByNode)
        {
            pill.setClass(StyleClass.VARIATION_NODE_SELECTED, node == selected);
            pill.setClass(StyleClass.VARIATION_NODE_OFF_LINE, node != selected && !onLine.exists(node));
        }
    }

    // edges on the selected line drawn last, so they show over the shared segments of the others
    private function rebuildEdges():Void
    {
        for (edge in edges)
            canvas.removeComponent(edge);
        edges = [];

        var onLine:Map<PlyTreeNode, Bool> = lineSet();
        var offLineSegments:Array<Box> = [];
        var onLineSegments:Array<Box> = [];
        for (cell in cells)
            if (!cell.node.isRoot())
            {
                var lineEdge:Bool = onLine.exists(cell.node);
                for (segment in edgeSegments(cell, lineEdge))
                    (lineEdge ? onLineSegments : offLineSegments).push(segment);
            }

        edges = offLineSegments.concat(onLineSegments);
        for (i in 0...edges.length)
            canvas.addComponentAt(edges[i], i);
    }

    private function edgeSegments(cell:TreeCell, onLine:Bool):Array<Box>
    {
        var parentCell:TreeCell = cellsByNode.get(cell.node.parent);
        var parentX:Float = Math.round(columnCentre(parentCell.column));
        var childX:Float = Math.round(columnCentre(cell.column));
        var parentBottom:Float = TOP_OFFSET + parentCell.row * ROW_HEIGHT + PILL_TOP + PILL_HEIGHT;
        var rowTop:Float = TOP_OFFSET + cell.row * ROW_HEIGHT;
        var childTop:Float = rowTop + PILL_TOP;
        var half:Float = EDGE_WIDTH / 2;

        if (parentX == childX)
            return [segment(parentX - half, parentBottom, EDGE_WIDTH, childTop - parentBottom, onLine)];

        return [
            segment(parentX - half, parentBottom, EDGE_WIDTH, rowTop - parentBottom + half, onLine),
            segment(Math.min(parentX, childX) - half, rowTop - half, Math.abs(childX - parentX) + EDGE_WIDTH, EDGE_WIDTH, onLine),
            segment(childX - half, rowTop, EDGE_WIDTH, childTop - rowTop, onLine)
        ];
    }

    private function segment(left:Float, top:Float, width:Float, height:Float, onLine:Bool):Box
    {
        var edge:Box = new Box();
        edge.addClass(StyleClass.VARIATION_EDGE);
        edge.setClass(StyleClass.VARIATION_EDGE_ON_LINE, onLine);
        edge.left = left;
        edge.top = top;
        edge.width = width;
        edge.height = height;
        return edge;
    }

    private function columnCentre(column:Int):Float
    {
        return columnX[column] + columnWidths[column] / 2;
    }

    private function lineSet():Map<PlyTreeNode, Bool>
    {
        var nodes:Map<PlyTreeNode, Bool> = [];
        if (selected != null)
            for (node in selected.line())
                nodes.set(node, true);
        return nodes;
    }

    private function revealSelected():Void
    {
        var cell:Null<TreeCell> = selected != null ? cellsByNode.get(selected) : null;
        if (cell == null)
            return;

        Toolkit.callLater(() -> {
            var element:js.html.Element = scroller.element;
            var width:Float = cell.node.isRoot() ? ROOT_WIDTH : columnWidths[cell.column];
            var left:Float = columnX[cell.column] * scale;
            var right:Float = (columnX[cell.column] + width) * scale;
            var top:Float = (TOP_OFFSET + cell.row * ROW_HEIGHT) * scale;
            var bottom:Float = top + ROW_HEIGHT * scale;
            var gutterWidth:Float = GUTTER_WIDTH * scale;

            if (left - gutterWidth < element.scrollLeft)
                element.scrollLeft = Math.floor(left - gutterWidth - LEFT_PADDING);
            else if (right > element.scrollLeft + element.clientWidth)
                element.scrollLeft = Math.ceil(right - element.clientWidth + RIGHT_PADDING);

            if (top < element.scrollTop)
                element.scrollTop = Math.floor(top);
            else if (bottom > element.scrollTop + element.clientHeight - BOTTOM_PADDING)
                element.scrollTop = Math.ceil(bottom - element.clientHeight + BOTTOM_PADDING);
        });
    }
}
