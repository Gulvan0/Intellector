package gfx.live.common.action_bar;

import haxe.ui.components.Button;
import haxe.ui.containers.HorizontalButtonBar;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game/action_buttons.xml"))
class ActionButtons extends HorizontalButtonBar
{
    private static inline final BUTTON_HEIGHT:Float = 36;

    public var btnPressHandler:ActionBtn->Void;

    private var buttonMap:Map<ActionButtonInternal, Button> = [];

    public function setButtons(buttons:Array<ActionButton>) 
    {
        removeAllComponents();
        buttonMap = [];
        
        for (button in buttons)
        {
            var buttonComponent:Button = constructButtonComponent(button);
            addComponent(buttonComponent);
            buttonMap.set(button, buttonComponent);
        }
    }

    public function replaceButton(oldBtn:ActionButton, newBtn:ActionButton)
    {
        var newBtnComponent:Button = constructButtonComponent(newBtn);
        var oldBtnComponent:Button = buttonMap.get(oldBtn);

        var index:Int = getComponentIndex(oldBtnComponent);

        if (index >= 0)
        {
            removeComponentAt(index);
            buttonMap.remove(oldBtn);
            
            addComponentAt(newBtnComponent, index);
            buttonMap.set(newBtn, newBtnComponent);
        }
    }

    private function constructButtonComponent(button:ActionButton, percentWidth:Float):Button
    {
        var buttonComponent:Button = new Button();
        buttonComponent.percentWidth = percentWidth;
        buttonComponent.height = BUTTON_HEIGHT;
        buttonComponent.tooltip = button.tooltip();
        buttonComponent.icon = button.iconPath();
        buttonComponent.styleNames = "action-button";
        buttonComponent.onClick = e -> {btnPressHandler(button);};
        return buttonComponent;
    }
}