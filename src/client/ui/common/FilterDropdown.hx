package client.ui.common;

import client.datatypes.timecontrol.TimeControlKind;
import client.formatters.Plurals;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.AnchorPlacement;
import haxefolio.Anchoring;
import haxefolio.ByWidth;
import haxefolio.ElementShadow;
import haxefolio.LocaleUtils;
import js.Browser;
import js.html.Event;
import js.html.Node;
import morestd.Detachable;

using client.ui.ComponentExtension;

typedef FilterOption =
{
    /** A locale binding **/
    caption:String,
    /** Shown as an icon before the caption **/
    ?kind:TimeControlKind
}

/**
    One facet of a filter bar: a button reading `<prefix> <value>` that opens a list of the facet's
    options, each with the number of items it would match. `multiple` facets are checkboxes (none
    checked means any) and stay open while toggled; the others are radios, the first option being
    the default, and close on a pick. An option matching nothing is greyed out in place unless selected.
**/
class FilterDropdown extends Box
{
    private static inline final POPUP_Z_INDEX:String = "20";

    private final options:Array<FilterOption>;
    private final multiple:Bool;
    private final onChanged:Array<Int>->Void;

    private final button:HBox;
    private final valueLabel:Label;
    private final chevron:Image;
    private final popup:VBox;
    private final rows:Array<HBox> = [];
    private final boxes:Array<Box> = [];
    private final countLabels:Array<Label> = [];

    private final emptyValue:String;

    private var selection:Array<Int>;
    private var counts:Array<Null<Int>>;
    private var lockedValue:Null<String> = null;
    private var anchoring:Null<Detachable> = null;

    /**
        `prefix`, `hint` and `emptyValue` are locale bindings; `hint`, if given, heads the list.
        `emptyValue` is what a `multiple` facet with nothing checked reads, Any by default.
        `onChanged` gets the new selection after each pick by the user.
    **/
    public function new(prefix:String, options:Array<FilterOption>, multiple:Bool, popupWidth:Int, onChanged:Array<Int>->Void, ?hint:String, ?emptyValue:String)
    {
        super();
        this.options = options;
        this.emptyValue = emptyValue ?? LocaleUtils.localeBinding("intellector.common.filter.any");
        this.multiple = multiple;
        this.onChanged = onChanged;
        this.selection = multiple ? [] : [0];
        this.counts = [for (_ in options) null];
        addClass(StyleClass.FILTER_DROPDOWN);

        button = new HBox();
        button.addClass(StyleClass.FILTER_BUTTON);
        button.trackHover();
        button.registerEvent(MouseEvent.CLICK, _ -> toggle());
        addComponent(button);

        var prefixLabel:Label = new Label();
        prefixLabel.text = prefix;
        prefixLabel.addClass(StyleClass.FILTER_BUTTON_TEXT);
        prefixLabel.verticalAlign = "center";
        button.addComponent(prefixLabel);

        valueLabel = new Label();
        valueLabel.addClass(StyleClass.FILTER_BUTTON_TEXT);
        valueLabel.verticalAlign = "center";
        button.addComponent(valueLabel);

        chevron = new Image();
        chevron.width = 12;
        chevron.height = 12;
        chevron.verticalAlign = "center";
        button.addComponent(chevron);

        popup = new VBox();
        popup.addClass(StyleClass.FILTER_POPUP);
        popup.width = popupWidth;
        popup.includeInLayout = false;
        popup.hidden = true;
        popup.element.style.zIndex = POPUP_Z_INDEX;
        ElementShadow.apply(popup.element, StyleVars.FILTER_POPUP_SHADOW);

        if (hint != null)
        {
            var hintLabel:Label = new Label();
            hintLabel.text = hint;
            hintLabel.addClass(StyleClass.FILTER_POPUP_HINT);
            popup.addComponent(hintLabel);
        }

        for (i in 0...options.length)
            popup.addComponent(createRow(i));

        addComponent(popup);
        render();
    }

    /** Renders `selection`: indices of the checked options, or the one picked radio **/
    public function setSelection(selection:Array<Int>):Void
    {
        this.selection = selection.copy();
        render();
    }

    /** The number of matches per option, null where unknown **/
    public function setCounts(counts:Array<Null<Int>>):Void
    {
        this.counts = counts.copy();
        render();
    }

    /** Disables the facet, reading `value` (a locale binding) instead of the selection; null unlocks it **/
    public function setLocked(value:Null<String>):Void
    {
        lockedValue = value;
        if (value != null)
            close();
        render();
    }

    public function close():Void
    {
        if (popup.hidden)
            return;

        popup.hidden = true;
        button.setClass(StyleClass.FILTER_BUTTON_OPEN, false);
        if (anchoring != null)
            anchoring.detach();
        anchoring = null;
        Browser.document.removeEventListener("pointerdown", onDocumentPointerDown, true);
    }

    private function toggle():Void
    {
        if (lockedValue != null)
            return;

        if (popup.hidden)
            open();
        else
            close();
    }

    private function open():Void
    {
        popup.hidden = false;
        button.setClass(StyleClass.FILTER_BUTTON_OPEN, true);
        var placement:AnchorPlacement = {side: Below, align: Start};
        anchoring = Anchoring.attach(popup, this, ByWidth.fromValue(placement));
        Browser.document.addEventListener("pointerdown", onDocumentPointerDown, true);
    }

    private function onDocumentPointerDown(event:Event):Void
    {
        var target:Node = cast event.target;
        if (!element.contains(target))
            close();
    }

    private function createRow(index:Int):HBox
    {
        var option:FilterOption = options[index];

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.FILTER_OPTION);
        row.trackHover();
        row.registerEvent(MouseEvent.CLICK, _ -> pick(index));

        var box:Box = new Box();
        box.addClass(multiple ? StyleClass.FILTER_CHECKBOX : StyleClass.FILTER_RADIO);
        box.verticalAlign = "center";
        if (multiple)
        {
            var check:Image = new Image();
            check.resource = Assets.controlIcon("check");
            check.width = 10;
            check.height = 10;
            check.horizontalAlign = "center";
            check.verticalAlign = "center";
            box.addComponent(check);
        }
        else
        {
            var dot:Box = new Box();
            dot.addClass(StyleClass.FILTER_RADIO_DOT);
            dot.horizontalAlign = "center";
            dot.verticalAlign = "center";
            box.addComponent(dot);
        }
        row.addComponent(box);

        if (option.kind != null)
            row.addComponent(new TimeControlKindIcon(option.kind));

        var captionLabel:Label = new Label();
        captionLabel.text = option.caption;
        captionLabel.percentWidth = 100;
        captionLabel.addClass(StyleClass.FILTER_OPTION_CAPTION);
        captionLabel.verticalAlign = "center";
        row.addComponent(captionLabel);

        var countLabel:Label = new Label();
        countLabel.addClass(StyleClass.FILTER_OPTION_COUNT);
        countLabel.verticalAlign = "center";
        row.addComponent(countLabel);

        rows.push(row);
        boxes.push(box);
        countLabels.push(countLabel);
        return row;
    }

    private function pick(index:Int):Void
    {
        if (isDisabled(index))
            return;

        if (!multiple)
        {
            close();
            if (selection[0] == index)
                return;
            selection = [index];
        }
        else if (selection.contains(index))
            selection = selection.filter(i -> i != index);
        else
            selection = [for (i in 0...options.length) if (i == index || selection.contains(i)) i];

        render();
        onChanged(selection.copy());
    }

    private function isDisabled(index:Int):Bool
    {
        return counts[index] == 0 && !selection.contains(index);
    }

    private function render():Void
    {
        var locked:Bool = lockedValue != null;
        var narrowed:Bool = !locked && (multiple ? selection.length > 0 : selection[0] != 0);

        button.setClass(StyleClass.FILTER_BUTTON_DISABLED, locked);
        button.setClass(StyleClass.FILTER_BUTTON_ACTIVE, narrowed);
        chevron.resource = Assets.controlIcon(locked ? "chevron_down_faint" : narrowed ? "chevron_down_accent" : "chevron_down");
        LocaleManager.instance.registerComponent(valueLabel, "text", valueText);

        for (i in 0...options.length)
        {
            var count:Null<Int> = counts[i];
            countLabels[i].hidden = count == null;
            countLabels[i].text = count != null ? Std.string(count) : "";
            rows[i].setClass(StyleClass.FILTER_OPTION_DISABLED, isDisabled(i));
            boxes[i].setClass(StyleClass.FILTER_BOX_ON, selection.contains(i));
        }
    }

    private function valueText():String
    {
        if (lockedValue != null)
            return LocaleUtils.resolveText(lockedValue);
        if (!multiple)
            return LocaleUtils.resolveText(options[selection[0]].caption);
        if (selection.length == 0)
            return LocaleUtils.resolveText(emptyValue);
        if (selection.length <= 2)
            return [for (i in selection) LocaleUtils.resolveText(options[i].caption)].join(", ");

        var key:String = Plurals.key("intellector.common.filter.kind_count", selection.length, LocaleManager.instance.language);
        return LocaleUtils.resolveText(LocaleUtils.localeBinding(key), selection.length);
    }
}
