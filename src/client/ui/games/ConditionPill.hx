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
    trails off with an ellipsis.
**/
class ConditionPill extends HBox
{
    /** Values shown before the rest are summed up as "+N more" **/
    private static inline final SHOWN_VALUES:Int = 3;

    private final condition:Condition;
    private final main:HBox;

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
            var style:CSSStyleDeclaration = label.getTextDisplay().element.style;
            style.overflow = "hidden";
            style.textOverflow = "ellipsis";
        }

        var hiddenCount:Int = condition.values.length - shown.length;
        if (hiddenCount > 0)
        {
            addText(() -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.pill.more", Std.string(hiddenCount))), StyleClass.GAMES_PILL_MORE);
            LocaleManager.instance.registerComponent(this, "tooltip", () -> condition.values.map(ArchiveFormatters.valueText).join("\n"));
        }
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
