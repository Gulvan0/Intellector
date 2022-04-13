package gfx;

import js.Browser;
import haxe.ui.styles.Style;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import openfl.display.Sprite;

//TODO: Create the section history and the "Back"/"Forward" buttons, which will make use of it
@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/screen_template.xml'))
class Screen extends VBox
{
    public function onEntered()
    {
        throw "To be overriden";
    }

    public function onClosed()
    {
        throw "To be overriden";
    }

    public function new()
    {
        super();
        //mainPageLink.customStyle = {fontName: "fonts/Futura.ttf", ...};
        //mainPageLink.onClick = e -> {ScreenManager.toScreen(new MainMenu());};
    }
}