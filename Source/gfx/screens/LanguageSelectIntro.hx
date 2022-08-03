package gfx.screens;

import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/simple_screens/lang_select.xml"))
class LanguageSelectIntro extends Screen
{
    private var onLangSelected:Void->Void;

    @:bind(ruBtn, MouseEvent.CLICK)
    private function onRuPressed(e)
    {
        Preferences.language.set(RU);
        onLangSelected();
    }

    @:bind(ruBtn, MouseEvent.CLICK)
    private function onEnPressed(e)
    {
        Preferences.language.set(EN);
        onLangSelected();
    }

    public function new(onLangSelected:Void->Void)
    {
        super(true);
        this.onLangSelected = onLangSelected;
        responsiveComponents = [
            this => [StyleProp(VerticalSpacing) => VMIN(8), StyleProp(PaddingTop) => VMIN(8)],
            headerLabel => [StyleProp(FontSize) => VMIN(12)],
            btnBox => [StyleProp(HorizontalSpacing) => VMIN(10)],
            enBtn => [Width => VMIN(38), Height => VMIN(20)],
            ruBtn => [Width => VMIN(30), Height => VMIN(20)]
        ];
    }
}