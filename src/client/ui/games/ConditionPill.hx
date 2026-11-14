package client.ui.games;

import client.datatypes.games.Condition;
import client.datatypes.games.EqualityValue;
import client.formatters.ArchiveFormatters;
import client.logic.games.ImplicitRestrictions;
import client.logic.games.ImplicitRestrictions.ImplicitRestriction;
import client.logic.games.PropertyCatalog;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import js.html.CSSStyleDeclaration;

using client.ui.ComponentExtension;

/**
    A property condition in the formula box: what it tests, a click target for editing it, an info
    icon naming its implicit restrictions and a cross deleting it. A partially filled condition
    trails off with an ellipsis, and so does a value list too long for the room given by `fit`.
**/
class ConditionPill extends HBox
{
    /** Values shown before the rest are summed up as "+N more" **/
    private static inline final SHOWN_VALUES:Int = 3;
    private static inline final MIN_VALUES_WIDTH:Float = 48;

    private final condition:Condition;
    private final main:HBox;
    /** The values and "+N more", each in a label of its own **/
    private final valueParts:Array<Label> = [];
    /** The same in one label, cut to fit; shown instead of `valueParts` while they don't fit **/
    private var compactValues:Null<Label> = null;
    /** The pill's width with every value part shown, measured before compacting **/
    private var naturalWidth:Null<Float> = null;

    /** `onEdit` and `onDelete` get the pill's condition **/
    public function new(condition:Condition, onEdit:Condition->Void, onDelete:Condition->Void)
    {
        super();
        this.condition = condition;
        addClass(StyleClass.GAMES_PILL);
        this.trackHover();

        main = new HBox();
        main.addClass(StyleClass.GAMES_PILL_MAIN);
        main.verticalAlign = "center";
        main.registerEvent(MouseEvent.CLICK, _ -> onEdit(condition));
        addComponent(main);
        fillMain();

        var restrictions:Array<ImplicitRestriction> = ImplicitRestrictions.of(condition);
        if (restrictions.length > 0)
        {
            var info:Image = new Image();
            info.resource = Assets.gamesIcon("info");
            info.addClass(StyleClass.GAMES_PILL_INFO);
            info.verticalAlign = "center";
            LocaleManager.instance.registerComponent(info, "tooltip", () -> ArchiveFormatters.restrictions(restrictions));
            addComponent(info);
        }

        addComponent(createDeleteButton(StyleClass.GAMES_PILL_CROSS, () -> onDelete(condition)));
    }

    /** A round cross button, as pills and groups have **/
    public static function createDeleteButton(styleClass:StyleClass, onClick:Void->Void):Box
    {
        var button:Box = new Box();
        button.addClass(styleClass);
        button.verticalAlign = "center";
        button.trackHover();
        button.registerEvent(MouseEvent.CLICK, _ -> onClick());

        var cross:Image = new Image();
        cross.resource = Assets.gamesIcon("cross");
        cross.horizontalAlign = "center";
        cross.verticalAlign = "center";
        button.addComponent(cross);
        return button;
    }

    /** Cuts the value list with an ellipsis while the pill is wider than `maxWidth`, restores it once there is room **/
    public function fit(maxWidth:Float):Void
    {
        if (compactValues == null)
            return;

        var compact:Bool = !compactValues.hidden;
        if (!compact)
            naturalWidth = element.getBoundingClientRect().width;
        if (naturalWidth == null || naturalWidth <= maxWidth)
        {
            if (compact)
                setCompact(false);
            return;
        }

        var valuesWidth:Float = compact ? compactValues.element.getBoundingClientRect().width : spanWidth(valueParts);
        var otherWidth:Float = element.getBoundingClientRect().width - valuesWidth;
        compactValues.width = Math.max(MIN_VALUES_WIDTH, maxWidth - otherWidth);
        if (!compact)
            setCompact(true);
    }

    private function setCompact(compact:Bool):Void
    {
        compactValues.hidden = !compact;
        for (part in valueParts)
            part.hidden = compact;
    }

    private function fillMain():Void
    {
        addText(() -> ArchiveFormatters.conditionSubject(condition.property, condition.parameter), StyleClass.GAMES_PILL_TEXT);

        var parameterMissing:Bool = PropertyCatalog.parameterType(condition.property) != null && condition.parameter == null;
        if (parameterMissing)
        {
            addEllipsis();
            return;
        }

        if (PropertyCatalog.isOperatorProperty(condition.property))
            fillOperatorPart();
        else
            fillValuesPart();
    }

    private function fillOperatorPart():Void
    {
        if (condition.conditionOperator == null)
        {
            addEllipsis();
            return;
        }

        addText(() -> ArchiveFormatters.operatorSymbol(condition.conditionOperator), StyleClass.GAMES_PILL_OPERATOR);
        var expected:Int = PropertyCatalog.operandCount(condition.conditionOperator);
        for (i in 0...expected)
        {
            if (i > 0)
                addText(ArchiveFormatters.boundsConjunction, StyleClass.GAMES_PILL_OPERATOR);
            if (i >= condition.operands.length)
            {
                addEllipsis();
                return;
            }
            var operandIndex:Int = i;
            addText(() -> ArchiveFormatters.operandText(condition.operands[operandIndex]), StyleClass.GAMES_PILL_MONO);
        }
    }

    private function fillValuesPart():Void
    {
        addText(() -> "=", StyleClass.GAMES_PILL_OPERATOR);
        if (condition.values.length == 0)
        {
            addEllipsis();
            return;
        }

        var shown:Array<EqualityValue> = condition.values.slice(0, SHOWN_VALUES);
        for (i in 0...shown.length)
        {
            var value:EqualityValue = shown[i];
            var last:Bool = i == shown.length - 1;
            var label:Label = addText(() -> ArchiveFormatters.valueText(value) + (last ? "" : ","), StyleClass.GAMES_PILL_VALUE);
            cutWithEllipsis(label);
            valueParts.push(label);
        }

        var hiddenCount:Int = condition.values.length - shown.length;
        var more:Void->String = () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.pill.more", Std.string(hiddenCount)));
        if (hiddenCount > 0)
        {
            valueParts.push(addText(more, StyleClass.GAMES_PILL_MORE));
            LocaleManager.instance.registerComponent(this, "tooltip", () -> condition.values.map(ArchiveFormatters.valueText).join("\n"));
        }

        compactValues = addText(() -> {
            var text:String = shown.map(ArchiveFormatters.valueText).join(", ");
            return hiddenCount > 0 ? '$text ${more()}' : text;
        }, StyleClass.GAMES_PILL_VALUES_COMPACT);
        cutWithEllipsis(compactValues);
        compactValues.hidden = true;
    }

    /** From the left edge of the first of `parts` to the right edge of the last **/
    private static function spanWidth(parts:Array<Label>):Float
    {
        return parts[parts.length - 1].element.getBoundingClientRect().right - parts[0].element.getBoundingClientRect().left;
    }

    private static function cutWithEllipsis(label:Label):Void
    {
        var style:CSSStyleDeclaration = label.getTextDisplay().element.style;
        style.overflow = "hidden";
        style.textOverflow = "ellipsis";
    }

    private function addText(text:Void->String, styleClass:StyleClass):Label
    {
        var label:Label = new Label();
        label.addClass(styleClass);
        label.verticalAlign = "center";
        LocaleManager.instance.registerComponent(label, "text", text);
        main.addComponent(label);
        return label;
    }

    private function addEllipsis():Void
    {
        addText(() -> "…", StyleClass.GAMES_PILL_PENDING);
    }
}
