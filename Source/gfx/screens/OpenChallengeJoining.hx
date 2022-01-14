package gfx.screens;

import haxe.ui.components.Button;
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import dict.Dictionary;
import js.Browser;
import Networker.OpenChallengeData;
import openfl.display.Sprite;

class OpenChallengeJoining extends Sprite 
{
    private static var boxWidth:Float = 800;

	//TODO: Rewrite
    public function new(data:Dynamic)
    {
		super();
        var joinMenu = new VBox();
		joinMenu.width = boxWidth;

		var label = new haxe.ui.components.Label();
		label.width = boxWidth;
		label.text = Dictionary.isHostingAChallengeText(data);
		if (LoginManager.login == null)
			label.text += Dictionary.getPhrase(WILL_BE_GUEST);
		else
			label.text += Dictionary.getPhrase(JOINING_AS) + LoginManager.login;
		label.customStyle = {fontSize: 16};
		label.textAlign = 'center';
		joinMenu.addComponent(label);

		var joinButton = new haxe.ui.components.Button();
		joinButton.width = 200;
		joinButton.horizontalAlign = 'center';
		joinButton.text = Dictionary.getPhrase(ACCEPT_CHALLENGE);
		joinMenu.addComponent(joinButton);

		joinButton.onClick = (e) -> {
			Networker.emitEvent(AcceptOpenChallenge(data.challenger));
		}

		joinMenu.x = (Browser.window.innerWidth - boxWidth) / 2;
		joinMenu.y = 100;
		addChild(joinMenu);

		var returnBtn = new Button();
		returnBtn.width = 100;
		returnBtn.text = Dictionary.getPhrase(RETURN);
		returnBtn.onClick = (e) -> {
			if (LoginManager.login != null)
				ScreenManager.instance.toMain();
			else
				Networker.dropConnection();
		};
            
        returnBtn.x = 10;
	    returnBtn.y = 10;
	    addChild(returnBtn);
    }
}