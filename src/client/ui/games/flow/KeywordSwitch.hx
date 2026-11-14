package client.ui.games.flow;

import client.datatypes.games.GroupKind;
import haxe.ui.core.Component;
import haxefolio.LocaleUtils;

/** The dropdown under a switchable AND/OR keyword, offering the other one **/
class KeywordSwitch
{
    private static inline final WIDTH:Float = 300;

    private final surface:PopoverSurface;

    /** `onSwitch` once the other keyword is picked; `onDismissed` if the dropdown is left without a pick **/
    public function new(page:Component, keyword:Component, target:GroupKind, onSwitch:Void->Void, onDismissed:Void->Void)
    {
        surface = new PopoverSurface(page, keyword, onDismissed);
        var entries:Array<ChoiceEntry<GroupKind>> = [
            Fixed(target, () -> LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.games.keyword.$target')))
        ];
        var list:ChoiceList<GroupKind> = ChoiceList.single(entries, null, _ -> {
            surface.close();
            onSwitch();
        }, (a, b) -> a == b, WIDTH, null);
        surface.show(new FlowStep(null, list.content));
    }

    public function close():Void
    {
        surface.close();
    }
}
