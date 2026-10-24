package client.ui.analysis.variations;

import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import client.datatypes.variations.VariationViewMode;
import client.formatters.Plurals;
import client.formatters.VariationFormatters;
import client.ui.common.WidthObserver;
import client.ui.game.GameButtons;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import js.Browser;
import js.html.CSSStyleDeclaration;
import js.html.CanvasRenderingContext2D;

using client.ui.ComponentExtension;

typedef VariationsCardHandlers =
{
    onSelect:PlyTreeNode->Void,
    onDelete:Void->Void,
    onExpandToggled:Void->Void,
    /** Marks the selection as the card preview, or unmarks it if it's the marked one **/
    onPreviewToggled:Void->Void
}

/**
    The ply tree, as a tree or as text, with Delete for the selected move, zoom (tree only) and
    Expand. Deleting a move with continuations asks first, in a banner over the view's bottom.
    The node a study's card shows carries a badge, and a header button marks the selection as it.
**/
class VariationsCard extends VBox
{
    private static var measuringContext:Null<CanvasRenderingContext2D> = null;

    private final handlers:VariationsCardHandlers;
    private final header:HBox;
    private final titleLabel:Label;
    private final hintLabel:Label;
    private final previewButton:Button;
    private final deleteButton:HBox;
    private final deletePill:HBox;
    private final deletePillDisc:Box;
    private final deletePillText:Label;
    private final body:Box;
    private final treeView:VariationTreeView;
    private final textView:VariationTextView;
    private final zoomGroup:HBox;
    private final zoomOutButton:Button;
    private final zoomResetButton:Button;
    private final zoomInButton:Button;
    private final expandButton:Button;
    private final confirmation:VBox;
    private final confirmationLabel:Label;

    private var mode:VariationViewMode = TREE;
    private var tree:Null<PlyTree> = null;
    private var selected:Null<PlyTreeNode> = null;
    private var locked:Bool = false;
    private var previewNode:Null<PlyTreeNode> = null;
    private var previewAuto:Bool = false;
    private var hintWidth:Float = 0;

    public function new(handlers:VariationsCardHandlers)
    {
        super();
        this.handlers = handlers;
        percentWidth = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.VARIATIONS_CARD);

        header = new HBox();
        header.percentWidth = 100;
        header.addClass(StyleClass.VARIATIONS_HEADER);
        addComponent(header);

        var titles:VBox = new VBox();
        titles.percentWidth = 100;
        titles.verticalAlign = "center";
        titles.addClass(StyleClass.GAME_TIGHT_STACK);
        header.addComponent(titles);

        titleLabel = new Label();
        titleLabel.text = LocaleUtils.localeBinding("intellector.analysis.variations.title");
        titleLabel.addClass(StyleClass.GAME_CARD_TITLE);
        titles.addComponent(titleLabel);

        hintLabel = new Label();
        hintLabel.percentWidth = 100;
        hintLabel.addClass(StyleClass.GAME_HINT);
        hintLabel.addClass(StyleClass.VARIATIONS_HINT);
        titles.addComponent(hintLabel);
        LocaleManager.instance.registerComponent(hintLabel, "text", hintText);
        WidthObserver.observe(hintLabel, width -> {
            hintWidth = width;
            LocaleManager.instance.refreshFor(hintLabel);
        });

        previewButton = GameButtons.actionWithIcon(Assets.analysisIcon("card_preview"), "intellector.analysis.variations.preview_mark", handlers.onPreviewToggled, false);
        previewButton.addClass(StyleClass.VARIATIONS_PREVIEW_BUTTON);
        previewButton.verticalAlign = "center";
        LocaleManager.instance.registerComponent(previewButton, "tooltip", previewTooltip);
        header.addComponent(previewButton);

        deleteButton = new HBox();
        deleteButton.addClass(StyleClass.GAME_BUTTON);
        deleteButton.addClass(StyleClass.VARIATIONS_DELETE);
        deleteButton.verticalAlign = "center";
        deleteButton.tooltip = LocaleUtils.localeBinding("intellector.analysis.variations.delete_hint");
        deleteButton.onClick = _ -> onDeletePressed();
        deleteButton.trackHover();
        deleteButton.trackPress();
        header.addComponent(deleteButton);

        var deleteIcon:Image = new Image();
        deleteIcon.resource = Assets.analysisIcon("delete");
        deleteIcon.verticalAlign = "center";
        deleteButton.addComponent(deleteIcon);

        var deleteCaption:Label = new Label();
        deleteCaption.text = LocaleUtils.localeBinding("intellector.analysis.variations.delete");
        deleteCaption.addClass(StyleClass.VARIATIONS_DELETE_CAPTION);
        deleteCaption.verticalAlign = "center";
        deleteButton.addComponent(deleteCaption);

        deletePill = new HBox();
        deletePill.addClass(StyleClass.VARIATIONS_DELETE_PILL);
        deletePill.verticalAlign = "center";
        deletePillDisc = VariationDisc.create(White);
        deletePill.addComponent(deletePillDisc);
        deletePillText = new Label();
        deletePillText.verticalAlign = "center";
        deletePill.addComponent(deletePillText);
        deleteButton.addComponent(deletePill);

        body = new Box();
        body.percentWidth = 100;
        body.percentHeight = 100;
        body.addClass(StyleClass.VARIATIONS_BODY);
        addComponent(body);

        treeView = new VariationTreeView(selectUnlessLocked);
        treeView.onScaleChanged = _ -> refreshZoom();
        textView = new VariationTextView(selectUnlessLocked);

        var tools:HBox = new HBox();
        tools.addClass(StyleClass.VARIATIONS_TOOLS);
        tools.horizontalAlign = "right";
        tools.verticalAlign = "bottom";

        zoomGroup = new HBox();
        zoomGroup.addClass(StyleClass.VARIATIONS_TOOL_GROUP);
        zoomOutButton = toolButton("zoom_out", "intellector.analysis.variations.zoom_out", treeView.zoomOut);
        zoomResetButton = new Button();
        zoomResetButton.addClass(StyleClass.GAME_BUTTON);
        zoomResetButton.addClass(StyleClass.VARIATIONS_ZOOM_PERCENT);
        zoomResetButton.tooltip = LocaleUtils.localeBinding("intellector.analysis.variations.zoom_reset");
        zoomResetButton.onClick = _ -> treeView.setScale(1);
        zoomInButton = toolButton("zoom_in", "intellector.analysis.variations.zoom_in", treeView.zoomIn);
        for (button in [zoomOutButton, zoomResetButton, zoomInButton])
            zoomGroup.addComponent(button);
        tools.addComponent(zoomGroup);

        var expandGroup:HBox = new HBox();
        expandGroup.addClass(StyleClass.VARIATIONS_TOOL_GROUP);
        expandButton = toolButton("expand", "intellector.analysis.variations.expand", handlers.onExpandToggled);
        expandGroup.addComponent(expandButton);
        tools.addComponent(expandGroup);

        confirmation = new VBox();
        confirmation.percentWidth = 100;
        confirmation.verticalAlign = "bottom";
        confirmation.addClass(StyleClass.VARIATIONS_CONFIRMATION);
        confirmation.hidden = true;
        confirmationLabel = new Label();
        confirmationLabel.percentWidth = 100;
        confirmationLabel.addClass(StyleClass.VARIATIONS_CONFIRMATION_TEXT);
        confirmation.addComponent(confirmationLabel);
        var confirmationButtons:HBox = new HBox();
        confirmationButtons.horizontalAlign = "right";
        confirmationButtons.addClass(StyleClass.GAME_ACTIONS_ROW);
        var cancelButton:Button = new Button();
        cancelButton.text = LocaleUtils.localeBinding("intellector.analysis.variations.cancel");
        cancelButton.addClass(StyleClass.GAME_BUTTON);
        cancelButton.onClick = _ -> hideConfirmation();
        confirmationButtons.addComponent(cancelButton);
        var confirmButton:Button = new Button();
        confirmButton.text = LocaleUtils.localeBinding("intellector.analysis.variations.delete");
        confirmButton.addClass(StyleClass.GAME_BUTTON);
        confirmButton.addClass(StyleClass.GAME_BUTTON_PRIMARY);
        confirmButton.onClick = _ -> {
            hideConfirmation();
            handlers.onDelete();
        };
        confirmationButtons.addComponent(confirmButton);
        confirmation.addComponent(confirmationButtons);

        body.addComponent(treeView);
        body.addComponent(textView);
        body.addComponent(tools);
        body.addComponent(confirmation);

        setMode(TREE);
        refreshZoom();
    }

    public function setMode(mode:VariationViewMode):Void
    {
        this.mode = mode;
        treeView.hidden = mode != TREE;
        textView.hidden = mode == TREE;
        zoomGroup.hidden = mode != TREE;
        if (tree != null)
            showTree(tree, selected);
    }

    /** After a structural change: redraws the view **/
    public function showTree(tree:PlyTree, selected:PlyTreeNode):Void
    {
        this.tree = tree;
        this.selected = selected;
        hideConfirmation();
        if (mode == TREE)
            treeView.showTree(tree.root, selected);
        else
            textView.showTree(tree.root, selected);
        refreshHeader();
    }

    /** Badges `node` as the card preview, `auto` while it's that by default; null hides the badge and the toggle **/
    public function setCardPreview(node:Null<PlyTreeNode>, auto:Bool):Void
    {
        previewNode = node;
        previewAuto = auto;
        treeView.setCardPreview(node, auto);
        textView.setCardPreview(node, auto);
        refreshHeader();
    }

    public function select(selected:PlyTreeNode):Void
    {
        this.selected = selected;
        hideConfirmation();
        if (mode == TREE)
            treeView.select(selected);
        else
            textView.select(selected);
        refreshHeader();
    }

    /** Disabled in place while the position editor is open **/
    public function setLocked(locked:Bool):Void
    {
        this.locked = locked;
        this.setClass(StyleClass.ANALYSIS_LOCKED, locked);
        invalidateComponentStyle(true, true); // descendant selectors depend on it
        hideConfirmation();
        expandButton.disabled = locked;
        refreshZoom();
        refreshHeader();
    }

    public function setExpanded(expanded:Bool):Void
    {
        GameButtons.setCaption(expandButton, expanded ? "intellector.analysis.variations.collapse" : "intellector.analysis.variations.expand", false);
        expandButton.icon = Assets.analysisIcon(expanded ? "collapse" : "expand");
    }

    /** Hidden while a tab names the card **/
    public function setTitleShown(shown:Bool):Void
    {
        titleLabel.hidden = !shown;
    }

    /** Hidden, the card is reduced to whatever is added above its content, such as tabs **/
    public function setContentShown(shown:Bool):Void
    {
        header.hidden = !shown;
        body.hidden = !shown;
    }

    private function selectUnlessLocked(node:PlyTreeNode):Void
    {
        if (!locked)
            handlers.onSelect(node);
    }

    private function onDeletePressed():Void
    {
        if (locked || selected == null || selected.isRoot())
            return;

        var continuationCount:Int = selected.subtreeSize() - 1;
        if (continuationCount == 0)
        {
            handlers.onDelete();
            return;
        }

        var notation:String = VariationFormatters.notation(selected);
        LocaleManager.instance.registerComponent(confirmationLabel, "text", () -> {
            var key:String = Plurals.key("intellector.analysis.variations.delete_confirm", continuationCount, Preferences.language.get());
            return LocaleUtils.resolveText(LocaleUtils.localeBinding(key), notation, continuationCount);
        });
        confirmation.hidden = false;
    }

    private function hideConfirmation():Void
    {
        confirmation.hidden = true;
    }

    private function refreshHeader():Void
    {
        var deletable:Bool = selected != null && !selected.isRoot();
        deleteButton.disabled = locked || !deletable;
        deletePill.hidden = !deletable;
        if (deletable)
        {
            deletePillText.text = VariationFormatters.notation(selected);
            var white:Bool = selected.moverColor() == White;
            deletePillDisc.setClass(StyleClass.VARIATION_DISC_WHITE, white);
            deletePillDisc.setClass(StyleClass.VARIATION_DISC_BLACK, !white);
        }
        LocaleManager.instance.refreshFor(hintLabel); // assigning the text would drop its locale binding

        var marked:Bool = isSelectionMarked();
        previewButton.hidden = previewNode == null;
        previewButton.disabled = locked || selected == null;
        previewButton.setClass(StyleClass.GAME_BUTTON_ON, marked);
        previewButton.icon = Assets.analysisIcon(marked ? "card_preview_on" : "card_preview");
        LocaleManager.instance.refreshFor(previewButton);
    }

    private function isSelectionMarked():Bool
    {
        return previewNode != null && !previewAuto && previewNode == selected;
    }

    private function previewTooltip():String
    {
        if (isSelectionMarked())
            return LocaleUtils.localeBinding("intellector.analysis.variations.preview_unmark");
        if (selected == null || selected.isRoot())
            return LocaleUtils.localeBinding("intellector.analysis.variations.preview_mark_root");
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.analysis.variations.preview_mark"), VariationFormatters.notation(selected));
    }

    private function hintText():String
    {
        if (tree == null)
            return "";

        var language:String = Preferences.language.get();
        var moveCount:Int = tree.moveCount();
        var lineCount:Int = tree.lineCount();
        var moves:String = LocaleUtils.resolveText(LocaleUtils.localeBinding(Plurals.key("intellector.analysis.variations.move_count", moveCount, language)), moveCount);
        var lines:String = LocaleUtils.resolveText(LocaleUtils.localeBinding(Plurals.key("intellector.analysis.variations.line_count", lineCount, language)), lineCount);
        var oneLine:String = '$moves · $lines';
        return hintWidth > 0 && singleLineWidth(oneLine) > hintWidth ? '$moves\n$lines' : oneLine;
    }

    private function singleLineWidth(text:String):Float
    {
        if (measuringContext == null)
            measuringContext = Browser.document.createCanvasElement().getContext2d();

        var style:CSSStyleDeclaration = Browser.window.getComputedStyle(hintLabel.getTextDisplay().element);
        measuringContext.font = '${style.fontStyle} ${style.fontWeight} ${style.fontSize} ${style.fontFamily}';
        return Math.ceil(measuringContext.measureText(text).width);
    }

    private function refreshZoom():Void
    {
        var scale:Float = treeView.getScale();
        zoomResetButton.text = Math.round(scale * 100) + "%";
        zoomOutButton.disabled = locked || scale <= VariationTreeView.ZOOM_STEPS[0] + 0.001;
        zoomInButton.disabled = locked || scale >= VariationTreeView.ZOOM_STEPS[VariationTreeView.ZOOM_STEPS.length - 1] - 0.001;
        zoomResetButton.disabled = locked;
    }

    private function toolButton(iconName:String, captionKey:String, onPress:Void->Void):Button
    {
        var button:Button = GameButtons.actionWithIcon(Assets.analysisIcon(iconName), captionKey, onPress, false);
        button.addClass(StyleClass.VARIATIONS_TOOL_BUTTON);
        return button;
    }
}
