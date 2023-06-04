package gfx.screens;

import gfx.scene.Screen;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import net.shared.dataobj.ViewedScreen;
import dict.Phrase;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/screens/language_select_intro.xml"))
class LanguageSelectIntro extends Screen
{
    private var onLangSelected:Void->Void;

    public function getTitle():Null<Phrase>
    {
        return null;
    }

    public function getURLPath():Null<String>
    {
        return null;
    }

    public function getPage():ViewedScreen
    {
        return Other;
    }

    private function onEnter():Void
    {
        //* Do nothing
    }

    private function onClose():Void
    {
        //* Do nothing
    }

    private function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>
    {
        return [
            this => [StyleProp(VerticalSpacing) => VMIN(8), StyleProp(PaddingTop) => VMIN(8)],
            headerLabel => [StyleProp(FontSize) => VMIN(12)],
            btnBox => [StyleProp(HorizontalSpacing) => VMIN(10)],
            enBtn => [Width => VMIN(38), Height => VMIN(20)],
            ruBtn => [Width => VMIN(30), Height => VMIN(20)]
        ];
    }

    @:bind(ruBtn, MouseEvent.CLICK)
    private function onRuPressed(e)
    {
        Preferences.language.set(RU, true);
        onLangSelected();
    }

    @:bind(enBtn, MouseEvent.CLICK)
    private function onEnPressed(e)
    {
        Preferences.language.set(EN, true);
        onLangSelected();
    }

    public function new(onLangSelected:Void->Void)
    {
        super(true);
        this.onLangSelected = onLangSelected;
    }
}