package gfx.screens;

import haxe.ui.events.MouseEvent;
import haxe.ui.core.Screen;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/simple_screens/lang_select.xml"))
class LanguageSelectIntro extends VBox implements IScreen
{
    private var onLangSelected:Void->Void;

    public function onEntered()
    {
        updateLayout();
        ScreenManager.addResizeHandler(updateLayout);
    }

    public function onClosed()
    {
        ScreenManager.removeResizeHandler(updateLayout);
    }

    private function updateLayout()
    {
        this.customStyle = {horizontalAlign: 'center', verticalSpacing: Math.min(0.08 * Screen.instance.width, 0.08 * Screen.instance.height), paddingTop: Math.min(0.08 * Screen.instance.width, 0.08 * Screen.instance.height)};
        headerLabel.customStyle = {fontSize: Math.min(0.12 * Screen.instance.width, 0.12 * Screen.instance.height)};
        btnBox.customStyle = {horizontalAlign: 'center', horizontalSpacing: Math.min(0.1 * Screen.instance.width, 0.1 * Screen.instance.height)};
        enBtn.width = Math.min(0.38 * Screen.instance.width, 0.38 * Screen.instance.height);
        enBtn.height = Math.min(0.2 * Screen.instance.width, 0.2 * Screen.instance.height);
        ruBtn.width = Math.min(0.3 * Screen.instance.width, 0.3 * Screen.instance.height);
        ruBtn.height = Math.min(0.2 * Screen.instance.width, 0.2 * Screen.instance.height);
    }

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

    public function menuHidden():Bool
    {
        return true;
    }

    public function asComponent():Component
    {
        return this;
    }

    public function new(onLangSelected:Void->Void)
    {
        super();
        this.onLangSelected = onLangSelected;
    }
}