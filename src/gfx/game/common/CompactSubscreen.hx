package gfx.game.common;

import gfx.game.interfaces.IGameComponent;
import gfx.scene.SceneManager;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/common/compact_subscreen.xml"))
class CompactSubscreen extends VBox
{
    public var inactive(default, null):Bool = false;

    public function displaySubscreen() 
    {
        if (!inactive)
            SceneManager.getScene().displaySubscreen(this);    
    }

    @:bind(backBtn, MouseEvent.CLICK)
    private function onBackPressed(e)
    {
        SceneManager.getScene().returnToMainScene();
    }

    public function setDisabled(subscreenDisabled:Bool) 
    {
        contentBox.disabled = subscreenDisabled;
    }

    public function setHidden(subscreenHidden:Bool) 
    {
        inactive = subscreenHidden;
    }

    public function updatePage(contentPageName:ComponentPageName):Array<IGameComponent>
    {
        var builder:ComponentPageBuilder = new ComponentPageBuilder(contentPageName);
        var page:Box = builder.buildPage();

        contentBox.removeAllComponents();
        contentBox.addComponent(page);
        subscreenNameLabel.text = page.text;

        return builder.allComponents();
    }

    public function new()
    {
        super();
    }
}