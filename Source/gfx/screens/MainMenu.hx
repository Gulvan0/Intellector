package gfx.screens;

import haxe.ui.events.MouseEvent;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/main_menu/main_menu.xml"))
class MainMenu extends Screen
{
    @:bind(createGameBtn, MouseEvent.CLICK)
    private function onCreateGamePressed(?e)
    {
        //TODO: same as for menuBar
    }

    //TODO: Changelog

    private override function validateComponentLayout():Bool 
    {
        var compact:Bool = HaxeUIScreen.instance.width / HaxeUIScreen.instance.height < 1.2;
        var wasCompact:Bool = tablesBox.percentWidth == 100;

        tablesBox.percentWidth = compact? 100 : 50;
        tablesBox.percentHeight = compact? 66.66 : 100;
        pastGamesList.percentWidth = compact? 100 : 50;
        pastGamesList.percentHeight = compact? 33.33 : 100;

        var parentChanged:Bool = super.validateComponentLayout();

        return parentChanged || wasCompact != compact;
    }

    public function new()
    {
        super();
    }
}