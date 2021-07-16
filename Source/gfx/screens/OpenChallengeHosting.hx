package gfx.screens;

import haxe.ui.styles.Style;
import js.Browser;
import url.URLEditor;
import dict.Dictionary;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;

class OpenChallengeHosting extends Sprite
{
    private static var hostingBoxWidth:Float = 800;

    public function new(startSecs:Int, bonusSecs:Int)
    {
		super();
        var hostingMenu = new VBox();
		hostingMenu.width = hostingBoxWidth;

		var firstLabel:Label = drawLabel();
		firstLabel.text = Dictionary.challengeByText(Networker.login, startSecs, bonusSecs);
		hostingMenu.addComponent(firstLabel);

		var linkText:TextField = new TextField();
		linkText.text = URLEditor.getChallengeLink(Networker.login);
		linkText.width = hostingBoxWidth;
		hostingMenu.addComponent(linkText);

		var secondLabel:Label = drawLabel();
		secondLabel.text = Dictionary.getPhrase(OPEN_CHALLENGE_FIRST_TO_FOLLOW_NOTE);
		hostingMenu.addComponent(secondLabel);

		hostingMenu.x = (Browser.window.innerWidth - hostingBoxWidth) / 2;
		hostingMenu.y = 100;
		addChild(hostingMenu);
    }

    private function drawLabel():Label
    {
        var label:Label = new Label();
		label.customStyle = new Style();
		label.customStyle.fontSize = 16;
		label.textAlign = 'center';
        label.width = hostingBoxWidth;
        return label;
    }
}