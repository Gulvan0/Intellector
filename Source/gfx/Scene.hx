package gfx;

import haxe.ui.containers.VBox;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/basic/scene_template.xml'))
class Scene extends VBox
{
    private var currentScreen:Null<Screen> = null;

    public function toScreen(type:Null<ScreenType>)
    {
        if (currentScreen != null)
        {
            currentScreen.onClosed();
            content.removeComponent(currentScreen);
        }

        if (type == null)
            currentScreen = null;
        else
        {
            currentScreen = Screen.build(type);
            menubar.hidden = currentScreen.menuHidden;
            content.addComponent(currentScreen);
            currentScreen.onEntered();
        }
    }

    private function invokeSideMenu()
    {
        //TODO: new Sidebar().show();
    }

    public function new()
    {
        super();
    }

}