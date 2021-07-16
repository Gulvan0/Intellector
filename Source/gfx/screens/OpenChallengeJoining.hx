package gfx.screens;

import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import dict.Dictionary;
import js.Browser;
import Networker.OpenChallengeData;
import openfl.display.Sprite;

class OpenChallengeJoining extends Sprite 
{
    private static var boxWidth:Float = 800;

    public function new(data:OpenChallengeData)
    {
		super();
        var joinMenu = new VBox();
		joinMenu.width = boxWidth;

		var label = new haxe.ui.components.Label();
		label.width = boxWidth;
		label.text = Dictionary.isHostingAChallengeText(data);
		if (Networker.login == null)
			label.text += Dictionary.getPhrase(WILL_BE_GUEST);
		else
			label.text += Dictionary.getPhrase(JOINING_AS) + Networker.login;
		label.customStyle = new Style();
		label.customStyle.fontSize = 16;
		label.textAlign = 'center';
		joinMenu.addComponent(label);

		var joinButton = new haxe.ui.components.Button();
		joinButton.width = 200;
		joinButton.horizontalAlign = 'center';
		joinButton.text = Dictionary.getPhrase(ACCEPT_CHALLENGE);
		joinMenu.addComponent(joinButton);

		joinButton.onClick = (e) -> {
			Networker.acceptOpen(data.challenger);
		}

		joinMenu.x = (Browser.window.innerWidth - boxWidth) / 2;
		joinMenu.y = 100;
		addChild(joinMenu);
    }
}