package gfx.game.common;

import haxe.ui.events.MouseEvent;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/compact_subscreen.xml"))
class CompactSubscreen extends VBox
{
    public function displaySubscreen() 
    {
        SceneManager.displaySubscreen(this);    
    }

    @:bind(backBtn, MouseEvent.CLICK)
    private function onBackPressed(e)
    {
        SceneManager.returnToMainScene();
    }

    public function new(contentPageName:ComponentPageName)
    {
        super();

        var builder:ComponentPageBuilder = new ComponentPageBuilder(contentPageName);
        var page:Box = builder.buildPage();

        contentBox.addComponent(page);
        subscreenNameLabel.text = page.text;
    }
}