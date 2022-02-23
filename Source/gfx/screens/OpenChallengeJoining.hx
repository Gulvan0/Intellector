package gfx.screens;

import net.LoginManager;
import haxe.ui.components.Button;
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import dict.Dictionary;
import js.Browser;
import dict.Utils;
import openfl.display.Sprite;

class OpenChallengeJoining extends Screen 
{
	private static var boxWidth:Float = 800;

	public override function onEntered()
    {
        //* Do nothing
    }

    public override function onClosed()
    {
        //* Do nothing
    }

    public override function getURLPath():String
    {
        return 'challenge';
    }

    public function new(challengeOwner:String, startSecs:Int, bonusSecs:Int, color:Null<String>)
    {
		super();
        var joinMenu = new VBox();
		joinMenu.width = boxWidth;

		var label = new haxe.ui.components.Label();
		label.width = boxWidth;
		label.text = Utils.isHostingAChallengeText(challengeOwner, startSecs, bonusSecs, color);
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
			Networker.emitEvent(AcceptOpenChallenge(challengeOwner));
		}

		joinMenu.x = (Browser.window.innerWidth - boxWidth) / 2;
		joinMenu.y = 100;
		content.addComponent(joinMenu);
    }
}