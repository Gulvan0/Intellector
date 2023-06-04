package gfx.game.common.action_bar;

import haxe.ui.containers.ButtonBar;
import gfx.game.common.action_bar.ActionButton.ActionButtonInternal;
import dict.Dictionary;
import js.Browser;
import dict.Phrase;
import haxe.ui.components.Button;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game/common/action_bar/action_buttons.xml"))
class ActionButtons extends ButtonBar
{
    private static inline final BUTTON_HEIGHT:Float = 36;

    public var btnPressHandler:ActionButton->Void;

    private var buttonMap:Map<ActionButtonInternal, Button> = [];
    private var buttonDisabled:Map<ActionButtonInternal, Bool> = [for (btn in ActionButtonInternal.createAll()) btn => false];

    public function setButtons(buttons:Array<ActionButton>) 
    {
        removeAllComponents();
        buttonMap = [];
        
        for (button in buttons)
        {
            var buttonComponent:Button = constructButtonComponent(button, 100 / buttons.length);
            addComponent(buttonComponent);
            buttonMap.set(button, buttonComponent);
        }
    }

    public function replaceButton(oldBtn:ActionButton, newBtn:ActionButton)
    {
        var oldBtnComponent:Button = buttonMap.get(oldBtn);
        var newBtnComponent:Button = constructButtonComponent(newBtn, oldBtnComponent.percentWidth);

        var index:Int = getComponentIndex(oldBtnComponent);

        if (index >= 0)
        {
            removeComponentAt(index);
            buttonMap.remove(oldBtn);
            
            addComponentAt(newBtnComponent, index);
            buttonMap.set(newBtn, newBtnComponent);
        }
    }

    public function setBtnDisabled(button:ActionButton, disabled:Bool)
    {
        buttonDisabled.set(button, disabled);

        var buttonComponent:Null<Button> = buttonMap.get(button);

        if (buttonComponent != null)
            buttonComponent.disabled = disabled;
    }

    private function constructButtonComponent(button:ActionButton, percentWidth:Float):Button
    {
        var buttonComponent:Button = new Button();
        buttonComponent.percentWidth = percentWidth;
        buttonComponent.height = BUTTON_HEIGHT;
        buttonComponent.tooltip = button.tooltip();
        buttonComponent.icon = button.iconPath();
        buttonComponent.styleNames = "action-button";
        buttonComponent.disabled = buttonDisabled.get(button);
        buttonComponent.onClick = e -> {
            var confirmationMessage:Null<Phrase> = button.confirmation();
            if (confirmationMessage == null)
                btnPressHandler(button);
            else if (Browser.window.confirm(Dictionary.getPhrase(confirmationMessage)))
                btnPressHandler(button);
        };
        return buttonComponent;
    }
}