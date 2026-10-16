package client.ui;

import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;

class ComponentExtension
{
    /** Also restyles the descendants, so rules like `.toggled .label` follow the toggle **/
    public static function setClass(component:Component, styleClass:StyleClass, present:Bool):Void
    {
        if (component.hasClass(styleClass) == present)
            return;

        if (present)
            component.addClass(styleClass);
        else
            component.removeClass(styleClass);
        component.invalidateComponentStyle(false, true); // HaxeUI's addClass/removeClass restyle the component alone
    }

    /** Maintains `:hover` on a component HaxeUI doesn't maintain it on: anything but its interactive components (Button, CheckBox...) **/
    public static function trackHover(component:Component):Void
    {
        component.registerEvent(MouseEvent.MOUSE_OVER, _ -> setPseudoClass(component, ":hover", true));
        component.registerEvent(MouseEvent.MOUSE_OUT, _ -> setPseudoClass(component, ":hover", false));
    }

    /** Maintains `:down` while pressed, on a component HaxeUI doesn't maintain it on (see `trackHover`) **/
    public static function trackPress(component:Component):Void
    {
        var pressed:Bool = false;
        component.registerEvent(MouseEvent.MOUSE_DOWN, _ -> {
            pressed = true;
            setPseudoClass(component, ":down", true);
        });
        component.registerEvent(MouseEvent.MOUSE_UP, _ -> {
            pressed = false;
            setPseudoClass(component, ":down", false);
        });
        // also crossing between its own children: the press shows again when the pointer comes back
        component.registerEvent(MouseEvent.MOUSE_OUT, _ -> setPseudoClass(component, ":down", false));
        component.registerEvent(MouseEvent.MOUSE_OVER, e -> setPseudoClass(component, ":down", pressed && e.buttonDown));
    }

    // restyles the descendants too, for rules like `.foo:hover .label`
    private static function setPseudoClass(component:Component, pseudoClass:String, present:Bool):Void
    {
        if (component.hasClass(pseudoClass) == present)
            return;

        if (present)
            component.addClass(pseudoClass, true, true);
        else
            component.removeClass(pseudoClass, true, true);
    }
}
