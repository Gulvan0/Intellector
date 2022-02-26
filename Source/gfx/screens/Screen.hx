package gfx.screens;

import js.Browser;
import haxe.ui.styles.Style;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import openfl.display.Sprite;

//TODO: Create the section history and the "Back"/"Forward" buttons, which will make use of it
class Screen extends Sprite
{
    private var mainVBox:VBox;
    private var topBar:HBox;
    private var content:Box;

    public function onEntered()
    {
        throw "To be overriden";
    }

    public function onClosed()
    {
        throw "To be overriden";
    }

    public function getURLPath():String
    {
        throw "To be overriden";
    }

    public function new()
    {
        super();
        var mainPageLink:Label = new Label();
        mainPageLink.text = "Intellector.info";
        mainPageLink.customStyle = {fontName: "fonts/Futura.ttf", fontSize: 25, color: 0x333333};
        mainPageLink.onClick = e -> {ScreenManager.toScreen(new MainMenu());};

        topBar = new HBox();
        topBar.width = Browser.window.innerWidth;
        topBar.height = 30;

        content = new Box();
        content.width = Browser.window.innerWidth;
        content.height = Browser.window.innerHeight - topBar.height - 5;

        mainVBox = new VBox();
        mainVBox.addComponent(topBar);
        mainVBox.addComponent(content);
        addChild(mainVBox);
    }
}