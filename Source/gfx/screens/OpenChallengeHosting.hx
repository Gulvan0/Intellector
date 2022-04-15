package gfx.screens;

import utils.TimeControl;
import net.LoginManager;
import js.html.Clipboard;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import struct.PieceColor;
import haxe.ui.styles.Style;
import js.Browser;
import browser.URLEditor;
import dict.Dictionary;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;

class OpenChallengeHosting extends Screen
{
	private static var hostingBoxWidth:Float = 800;
	private static var selectAllBtnWidth:Float = 30;

	public override function onEntered()
    {
        //* Do nothing
    }

    public override function onClosed()
    {
        //* Do nothing
    }

	
	//TODO: Revamp
    public function new(timeControl:TimeControl, color:Null<PieceColor>)
    {
		super();
		//TODO: Process TimeControl accordingly
        var hostingMenu = new VBox();
		hostingMenu.width = hostingBoxWidth;

		var firstLabel:Label = drawLabel();
		//firstLabel.text = dict.Utils.challengeByText(LoginManager.login, startSecs, bonusSecs, color);
		hostingMenu.addComponent(firstLabel);

		var linkBox:HBox = new HBox();

		var linkText:TextField = new TextField();
		linkText.text = URLEditor.getChallengeLink(LoginManager.login);
		linkText.width = hostingBoxWidth /*- copyBtnWidth - 5*/;
		linkBox.addComponent(linkText);

		/*var selectAllBtn = new Button();
		selectAllBtn.width = selectAllBtnWidth;
		selectAllBtn.text = "⧉";
		selectAllBtn.onClick = (e) -> {
			//Copy
			copyBtn.text = "✔";
		};
		linkBox.addComponent(selectAllBtn);*/

		hostingMenu.addComponent(linkBox);

		var secondLabel:Label = drawLabel();
		secondLabel.text = Dictionary.getPhrase(OPEN_CHALLENGE_FIRST_TO_FOLLOW_NOTE);
		hostingMenu.addComponent(secondLabel);

		hostingMenu.x = (Browser.window.innerWidth - hostingBoxWidth) / 2;
		hostingMenu.y = 100;
		content.addComponent(hostingMenu);

		var returnBtn = new Button();
		returnBtn.width = 100;
		returnBtn.text = Dictionary.getPhrase(RETURN);
		returnBtn.onClick = (e) -> {
			var confirmed = Browser.window.confirm(Dictionary.getPhrase(OPEN_CHALLENGE_CANCEL_CONFIRMATION));
			if (!confirmed)
				return;

			Networker.emitEvent(CancelOpenChallenge);
			ScreenManager.toScreen(MainMenu);
		};
            
        returnBtn.x = 10;
	    returnBtn.y = 10;
	    content.addComponent(returnBtn);
    }

    private function drawLabel():Label
    {
        var label:Label = new Label();
		label.customStyle = {fontSize: 16};
		label.textAlign = 'center';
        label.width = hostingBoxWidth;
        return label;
    }
}