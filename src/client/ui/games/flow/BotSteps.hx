package client.ui.games.flow;

import client.datatypes.bot.BotKind;
import client.datatypes.games.BotFilter;
import client.formatters.ArchiveFormatters;
import client.logic.bot.BotKinds;
import client.logic.bot.BotStrengthRules;
import haxefolio.LocaleUtils;

/**
    The `Bot` selector: a family, then for a Haxaconda one a level, each picked on click. "Any bot"
    and Anaconda end it at the first step, "Any level" at the second.
**/
class BotSteps
{
    private static inline final FAMILY_WIDTH:Float = 230;
    private static inline final LEVEL_WIDTH:Float = 200;

    /** `show` displays the level step in the family step's place **/
    public static function family(title:Void->String, initial:Null<BotFilter>, back:Null<Void->Void>, show:FlowStep->Void, onValue:BotFilter->Void):FlowStep
    {
        var step:Null<FlowStep> = null;
        var entries:Array<ChoiceEntry<BotFilter>> = [
            Fixed(AnyBot, text("intellector.games.step.bot.any")),
            Separator,
            Fixed(Anaconda, () -> ArchiveFormatters.playerName(Bot(Anaconda)))
        ];
        for (kind in BotKinds.ALL)
            entries.push(Fixed(AnyLevel(kind), () -> BotKinds.displayName(kind)));

        var current:Null<BotFilter> = switch initial {
            case Level(kind, _): AnyLevel(kind);
            default: initial;
        }
        var onPick:BotFilter->Void = picked -> switch picked {
            case AnyLevel(kind):
                show(level(kind, initial, () -> show(step), onValue));
            default:
                onValue(picked);
        };

        var list:ChoiceList<BotFilter> = ChoiceList.single(entries, current, onPick, Type.enumEq, FlowLayout.listWidth(FAMILY_WIDTH), null);
        step = new FlowStep(title, list.content, null, back);
        return step;
    }

    private static function level(kind:BotKind, initial:Null<BotFilter>, back:Void->Void, onValue:BotFilter->Void):FlowStep
    {
        var entries:Array<ChoiceEntry<BotFilter>> = [Fixed(AnyLevel(kind), text("intellector.games.step.bot.any_level")), Separator];
        for (level in BotStrengthRules.MIN_STRENGTH...BotStrengthRules.maxStrength(kind) + 1)
            entries.push(Fixed(Level(kind, level), () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.step.bot.level", Std.string(level)))));

        var current:Null<BotFilter> = switch initial {
            case Level(initialKind, _) if (initialKind == kind): initial;
            case AnyLevel(initialKind) if (initialKind == kind): initial;
            default: null;
        }
        var list:ChoiceList<BotFilter> = ChoiceList.single(entries, current, onValue, Type.enumEq, FlowLayout.listWidth(LEVEL_WIDTH), null);
        return new FlowStep(() -> BotKinds.displayName(kind), list.content, null, back);
    }

    private static function text(key:String):Void->String
    {
        return () -> LocaleUtils.resolveText(LocaleUtils.localeBinding(key));
    }
}
