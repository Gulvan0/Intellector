package client.ui.games.flow;

import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;

using client.ui.ComponentExtension;

typedef MultiChoiceOptions<T> =
{
    ticked:Array<T>,
    onConfirm:Array<T>->Void,
    /** The label of a value created through an appended option **/
    labelOf:T->String,
    /** The most values that may be ticked, and why, as a locale binding **/
    maxTicked:Int,
    capReason:String
}

/**
    A list of options: `SingleSelection` (a click on a fixed option picks it) or `MultiSelection`
    (checkboxes and a Confirm button). An appended option opens a prompt; in a multi-selection list,
    the value it gives becomes a ticked option of its own, after the fixed ones.
**/
class ChoiceList<T>
{
    private static inline final ROW_HEIGHT:Float = 37;
    private static inline final HEADING_HEIGHT:Float = 28;
    private static inline final SEPARATOR_HEIGHT:Float = 13;
    private static inline final LIST_PADDING:Float = 12;

    public final content:Component;
    /** Multi-selection only **/
    public final footer:Null<StepFooter>;

    private final entries:Array<ChoiceEntry<T>>;
    private final equals:(T, T)->Bool;
    private final list:VBox;
    private final multiOptions:Null<MultiChoiceOptions<T>>;
    private final onPick:Null<T->Void>;
    private final selected:Null<T>;
    /** Multi-selection: the values in the list's order, ticked or not, created ones included **/
    private final values:Array<T> = [];
    private final ticked:Array<T> = [];
    private final checkboxes:Array<Box> = [];
    private final rows:Array<HBox> = [];
    private final rowReasons:Array<Null<Void->String>> = [];

    /** Picks on click, marking `selected` as the current choice **/
    public static function single<T>(entries:Array<ChoiceEntry<T>>, selected:Null<T>, onPick:T->Void, equals:(T, T)->Bool, width:Null<Float>, maxHeight:Null<Float>):ChoiceList<T>
    {
        return new ChoiceList(entries, selected, onPick, null, equals, width, maxHeight);
    }

    public static function multi<T>(entries:Array<ChoiceEntry<T>>, options:MultiChoiceOptions<T>, equals:(T, T)->Bool, width:Null<Float>, maxHeight:Null<Float>):ChoiceList<T>
    {
        return new ChoiceList(entries, null, null, options, equals, width, maxHeight);
    }

    private function new(entries:Array<ChoiceEntry<T>>, selected:Null<T>, onPick:Null<T->Void>, multi:Null<MultiChoiceOptions<T>>, equals:(T, T)->Bool, width:Null<Float>, maxHeight:Null<Float>)
    {
        this.entries = entries;
        this.selected = selected;
        this.onPick = onPick;
        this.multiOptions = multi;
        this.equals = equals;

        list = new VBox();
        list.addClass(StyleClass.GAMES_CHOICE_LIST);
        if (width != null)
            list.width = width;
        else
            list.percentWidth = 100;

        if (multi != null)
        {
            for (value in multi.ticked)
                ticked.push(value);
            footer = new StepFooter(() -> multi.onConfirm(ticked.copy()));
        }
        else
            footer = null;

        render();
        content = maxHeight != null ? scrolled(list, width, maxHeight) : list;
        refreshTicks();
    }

    private function render():Void
    {
        list.removeAllComponents();
        values.resize(0);
        checkboxes.resize(0);
        rows.resize(0);
        rowReasons.resize(0);

        var createdShown:Bool = false;
        for (entry in entries)
            switch entry
            {
                case Heading(text):
                    list.addComponent(heading(text));
                case Separator:
                    if (!createdShown)
                    {
                        addCreatedRows();
                        createdShown = true;
                    }
                    list.addComponent(separator());
                case Fixed(value, label, icon, symbol, disabledReason):
                    list.addComponent(fixedRow(value, label, icon, symbol, disabledReason));
                case Appended(label, icon, open, owns):
                    if (!createdShown)
                    {
                        addCreatedRows();
                        createdShown = true;
                    }
                    list.addComponent(appendedRow(label, icon, open, owns));
            }
        if (!createdShown)
            addCreatedRows();
    }

    /** Multi-selection: the ticked values no fixed option holds, created through appended options **/
    private function addCreatedRows():Void
    {
        if (multiOptions == null)
            return;
        for (value in ticked)
            if (!holdsFixed(value))
                list.addComponent(fixedRow(value, () -> multiOptions.labelOf(value), iconOwning(value), null, null));
    }

    private function holdsFixed(value:T):Bool
    {
        for (entry in entries)
            switch entry
            {
                case Fixed(fixedValue, _, _, _, _) if (equals(fixedValue, value)):
                    return true;
                default:
            }
        return false;
    }

    private function iconOwning(value:T):Null<String>
    {
        for (entry in entries)
            switch entry
            {
                case Appended(_, icon, _, owns) if (owns(value)):
                    return icon;
                default:
            }
        return null;
    }

    private function fixedRow(value:T, label:Void->String, icon:Null<String>, symbol:Null<Void->String>, disabledReason:Null<Void->String>):HBox
    {
        var row:HBox = optionRow();
        if (multiOptions != null)
        {
            var box:Box = checkbox();
            row.addComponent(box);
            checkboxes.push(box);
            values.push(value);
            rows.push(row);
            rowReasons.push(disabledReason);
        }
        if (symbol != null)
            row.addComponent(text(symbol, StyleClass.GAMES_CHOICE_SYMBOL, false));
        if (icon != null)
            row.addComponent(iconImage(icon));
        row.addComponent(text(label, StyleClass.FILTER_OPTION_CAPTION, true));

        if (disabledReason != null)
        {
            row.addComponent(text(disabledReason, StyleClass.GAMES_CHOICE_REASON, false));
            row.addClass(StyleClass.FILTER_OPTION_DISABLED);
            return row;
        }

        row.trackHover();
        if (multiOptions != null)
            row.registerEvent(MouseEvent.CLICK, _ -> toggle(value));
        else
        {
            if (selected != null && equals(selected, value))
                row.addClass(StyleClass.GAMES_CHOICE_CURRENT);
            row.registerEvent(MouseEvent.CLICK, _ -> onPick(value));
        }
        return row;
    }

    private function appendedRow(label:Void->String, icon:Null<String>, open:(Component, T->Void)->Void, owns:T->Bool):HBox
    {
        var row:HBox = optionRow();
        row.addComponent(iconImage(Assets.gamesIcon("appended"), StyleClass.GAMES_CHOICE_PLUS));
        if (icon != null)
            row.addComponent(iconImage(icon));
        row.addComponent(text(label, StyleClass.FILTER_OPTION_CAPTION, true));
        row.trackHover();

        if (multiOptions == null && selected != null && owns(selected))
            row.addClass(StyleClass.GAMES_CHOICE_CURRENT);

        if (multiOptions != null)
        {
            rows.push(row);
            rowReasons.push(null);
            row.registerEvent(MouseEvent.CLICK, _ -> {
                if (ticked.length < multiOptions.maxTicked)
                    open(row, add);
            });
        }
        else
            row.registerEvent(MouseEvent.CLICK, _ -> open(row, onPick));
        return row;
    }

    /** Multi-selection: ticks a value given by a prompt, adding it as an option unless one holds it **/
    private function add(value:T):Void
    {
        if (indexIn(values, value) < 0)
        {
            ticked.push(value);
            render();
        }
        else if (indexIn(ticked, value) < 0)
            ticked.push(value);
        sortTicked();
        refreshTicks();
    }

    private function toggle(value:T):Void
    {
        var index:Int = indexIn(ticked, value);
        if (index >= 0)
            ticked.splice(index, 1);
        else if (ticked.length < multiOptions.maxTicked)
            ticked.push(value);
        sortTicked();
        refreshTicks();
    }

    // in the list's order, which is the selector's order the formula keeps
    private function sortTicked():Void
    {
        ticked.sort((a, b) -> indexIn(values, a) - indexIn(values, b));
    }

    private function refreshTicks():Void
    {
        if (multiOptions == null)
            return;

        var full:Bool = ticked.length >= multiOptions.maxTicked;
        for (i in 0...values.length)
        {
            var on:Bool = indexIn(ticked, values[i]) >= 0;
            checkboxes[i].setClass(StyleClass.FILTER_BOX_ON, on);
            if (rowReasons[i] == null)
            {
                rows[i].setClass(StyleClass.FILTER_OPTION_DISABLED, full && !on);
                rows[i].tooltip = full && !on ? multiOptions.capReason : null;
            }
        }
        for (i in values.length...rows.length)
        {
            rows[i].setClass(StyleClass.FILTER_OPTION_DISABLED, full);
            rows[i].tooltip = full ? multiOptions.capReason : null;
        }

        footer.enabled = ticked.length > 0;
        footer.info = ticked.length == 0 ? LocaleUtils.localeBinding("intellector.games.step.tick_one") : LocaleUtils.localeBinding("intellector.games.step.selected", Std.string(ticked.length));
    }

    private function indexIn(array:Array<T>, value:T):Int
    {
        for (i in 0...array.length)
            if (equals(array[i], value))
                return i;
        return -1;
    }

    private static function scrolled(list:VBox, width:Null<Float>, maxHeight:Float):Component
    {
        list.percentWidth = 100;
        var scroller:ScrollArea = new ScrollArea(list);
        scroller.addClass(StyleClass.GAMES_CHOICE_SCROLLER);
        if (width != null)
        {
            scroller.percentWidth = null;
            scroller.width = width;
        }
        scroller.height = Math.min(maxHeight, naturalHeight(list));
        return scroller;
    }

    private static function naturalHeight(list:VBox):Float
    {
        var height:Float = LIST_PADDING;
        for (child in list.childComponents)
            height += child.hasClass(StyleClass.GAMES_CHOICE_HEADING) ? HEADING_HEIGHT : child.hasClass(StyleClass.GAMES_CHOICE_SEPARATOR) ? SEPARATOR_HEIGHT : ROW_HEIGHT;
        return height;
    }

    private static function optionRow():HBox
    {
        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.FILTER_OPTION);
        return row;
    }

    private static function heading(text:Void->String):Label
    {
        var label:Label = new Label();
        label.percentWidth = 100;
        label.addClass(StyleClass.GAMES_CHOICE_HEADING);
        LocaleManager.instance.registerComponent(label, "text", text);
        return label;
    }

    private static function separator():Box
    {
        var line:Box = new Box();
        line.percentWidth = 100;
        line.addClass(StyleClass.GAMES_CHOICE_SEPARATOR);
        return line;
    }

    private static function checkbox():Box
    {
        var box:Box = new Box();
        box.addClass(StyleClass.FILTER_CHECKBOX);
        box.verticalAlign = "center";
        var check:Image = new Image();
        check.resource = Assets.controlIcon("check");
        check.width = 10;
        check.height = 10;
        check.horizontalAlign = "center";
        check.verticalAlign = "center";
        box.addComponent(check);
        return box;
    }

    private static function iconImage(resource:String, ?styleClass:StyleClass):Image
    {
        var image:Image = new Image();
        image.resource = resource;
        image.verticalAlign = "center";
        if (styleClass != null)
            image.addClass(styleClass);
        return image;
    }

    private static function text(text:Void->String, styleClass:StyleClass, fill:Bool):Label
    {
        var label:Label = new Label();
        if (fill)
            label.percentWidth = 100;
        label.addClass(styleClass);
        label.verticalAlign = "center";
        LocaleManager.instance.registerComponent(label, "text", text);
        return label;
    }
}
