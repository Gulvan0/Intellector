package gfx.screens;

import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/simple_screens/lang_select.xml"))
class LanguageSelectIntro extends Screen
{
    private var onLangSelected:Void->Void;

    public abstract function getTitle():Null<Phrase>
    {
        return null;
    }

    public abstract function getURLPath():Null<String>
    {
        return null;
    }

    public abstract function getPage():ViewedScreen
    {
        return Other;
    }

    private abstract function onEnter():Void
    {
        //* Do nothing
    }

    private abstract function onClose():Void
    {
        //* Do nothing
    }

    private abstract function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>
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