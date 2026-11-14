package client.ui.games.flow;

import client.datatypes.games.DurationUnit;
import client.datatypes.games.GameProperty;
import client.formatters.ArchiveFormatters;
import client.logic.games.DurationRules;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/**
    A `Duration` operand as one field per unit the property allows, largest first. A field clamps on
    losing focus: the ones below the largest to their unit's range, then the total to the property's.
**/
class DurationStep
{
    private static inline final BODY_WIDTH:Float = 330;

    private final property:GameProperty;
    private final units:Array<DurationUnit>;
    private final fields:Array<DigitField> = [];
    private final hint:Label;
    private final footer:StepFooter;
    private final lowerBoundMs:Null<Float>;

    /** `lowerBoundMs`: an upper bound's lower one, which it must exceed **/
    public static function create(property:GameProperty, title:Void->String, initialMs:Null<Float>, back:Null<Void->Void>, onValue:Float->Void, ?lowerBoundMs:Float):FlowStep
    {
        var step:DurationStep = new DurationStep(property, initialMs, onValue, lowerBoundMs);
        var content:VBox = new VBox();
        content.addClass(StyleClass.GAMES_STEP_BODY);
        FlowLayout.size(content, BODY_WIDTH);
        content.addComponent(step.row());
        content.addComponent(step.hint);
        return new FlowStep(title, content, step.footer, back, step.holdsText, step.focusFirst);
    }

    private function new(property:GameProperty, initialMs:Null<Float>, onValue:Float->Void, lowerBoundMs:Null<Float>)
    {
        this.property = property;
        this.lowerBoundMs = lowerBoundMs;
        units = DurationRules.units(property);

        hint = new Label();
        hint.percentWidth = 100;
        hint.addClass(StyleClass.GAMES_STEP_HINT);

        footer = new StepFooter(() -> {
            var total:Null<Float> = validTotal();
            if (total != null)
                onValue(total);
        });

        for (i in 0...units.length)
            fields.push(new DigitField(i == 0 ? 4 : 3, refresh, () -> clamp(i)));

        var parts:Array<Int> = DurationRules.split(initialMs ?? DurationRules.minMs(property), units);
        for (i in 0...units.length)
            fields[i].number = parts[i];
        refresh();
    }

    private function row():HBox
    {
        var row:HBox = new HBox();
        row.addClass(StyleClass.GAMES_DURATION_ROW);
        for (i in 0...units.length)
        {
            row.addComponent(fields[i]);
            var unitLabel:Label = new Label();
            unitLabel.text = LocaleUtils.localeBinding('intellector.games.step.duration.unit.${units[i].getName().toLowerCase()}');
            unitLabel.addClass(StyleClass.GAMES_DURATION_UNIT);
            unitLabel.verticalAlign = "center";
            row.addComponent(unitLabel);
        }
        return row;
    }

    private function holdsText():Bool
    {
        for (field in fields)
            if ((field.text ?? "") != "")
                return true;
        return false;
    }

    private function focusFirst():Void
    {
        fields[0].focusInput();
    }

    private function parts():Array<Int>
    {
        return [for (field in fields) field.number ?? 0];
    }

    private function clamp(index:Int):Void
    {
        var current:Array<Int> = parts();
        if (index > 0)
            current[index] = Std.int(Math.min(current[index], DurationRules.naturalMax(units[index])));

        var total:Float = DurationRules.join(current, units);
        var max:Null<Float> = DurationRules.maxMs(property);
        var clamped:Float = Math.max(DurationRules.minMs(property), max != null ? Math.min(total, max) : total);
        var shown:Array<Int> = clamped == total ? current : DurationRules.split(clamped, units);
        for (i in 0...fields.length)
            fields[i].number = shown[i];
        refresh();
    }

    private function total():Float
    {
        return DurationRules.join(parts(), units);
    }

    private function validTotal():Null<Float>
    {
        var value:Float = total();
        var max:Null<Float> = DurationRules.maxMs(property);
        if (value < DurationRules.minMs(property) || (max != null && value > max))
            return null;
        if (lowerBoundMs != null && value <= lowerBoundMs)
            return null;
        return value;
    }

    private function refresh():Void
    {
        var value:Float = total();
        var max:Null<Float> = DurationRules.maxMs(property);
        var belowLowerBound:Bool = lowerBoundMs != null && value <= lowerBoundMs;
        var outOfRange:Bool = value < DurationRules.minMs(property) || (max != null && value > max);

        if (belowLowerBound)
            hint.text = LocaleUtils.localeBinding("intellector.games.step.above_lower_bound", ArchiveFormatters.clock(lowerBoundMs));
        else if (max != null)
            hint.text = LocaleUtils.localeBinding("intellector.games.step.duration.range", ArchiveFormatters.clock(DurationRules.minMs(property)), ArchiveFormatters.clock(max));
        else
            hint.text = "";

        var invalid:Bool = belowLowerBound || outOfRange;
        hint.setClass(StyleClass.GAMES_STEP_HINT_ERROR, invalid);
        for (field in fields)
            field.setClass(StyleClass.GAMES_DIGIT_FIELD_INVALID, invalid);
        footer.enabled = !invalid;
    }
}
