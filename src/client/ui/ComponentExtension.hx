package client.ui;

import haxe.ui.core.Component;

class ComponentExtension
{
    public static function setClass(component:Component, styleClass:StyleClass, present:Bool):Void
    {
        if (present)
            component.addClass(styleClass);
        else
            component.removeClass(styleClass);
    }
}
