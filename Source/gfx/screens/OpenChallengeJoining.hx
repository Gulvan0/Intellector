package gfx.screens;

import gfx.Dialogs;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import utils.TimeControl;
import struct.PieceColor;
import haxe.ui.components.Button;
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import dict.Dictionary;
import js.Browser;
import dict.Utils;
import openfl.display.Sprite;
import utils.AssetManager;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/simple_screens/join_challenge.xml'))
class OpenChallengeJoining extends Screen
{
	private final challengeOwner:String;
	
	@:bind(acceptBtn, MouseEvent.CLICK)
	private function onAccepted(e)
	{
		if (LoginManager.isLogged())
			Networker.emitEvent(AcceptOpenChallenge(challengeOwner, null, null));
		else
		{
			LoginManager.generateOneTimeCredentials();
			Networker.emitEvent(AcceptOpenChallenge(challengeOwner, LoginManager.getLogin(), LoginManager.getPassword()));
		}
	}

    public function new(challengeOwner:String, timeControl:TimeControl, color:Null<PieceColor>, rated:Bool = false)
    {
		super();
		this.challengeOwner = challengeOwner;

		challengeByLabel.text = Dictionary.getPhrase(OPENJOIN_CHALLENGE_BY_HEADER, [challengeOwner]);
		tcIcon.resource = AssetManager.timeControlPath(timeControl.getType());
		tcLabel.text = timeControl.toString();
		if (timeControl.getType() != Correspondence)
			tcLabel.text += ' (${timeControl.getType().getName()})';
		bracketLabel.text = Dictionary.getPhrase(rated? OPENJOIN_RATED : OPENJOIN_UNRATED);
		colorLabel.text = switch color {
			case White: Dictionary.getPhrase(OPENJOIN_COLOR_WHITE_OWNER, [challengeOwner]);
			case Black: Dictionary.getPhrase(OPENJOIN_COLOR_BLACK_OWNER, [challengeOwner]);
			case null: Dictionary.getPhrase(OPENJOIN_COLOR_RANDOM);
		};

		responsiveComponents = [
			challengeByLabel => [StyleProp(FontSize) => VMIN(8)],
			firstSpacer => [Height => VMIN(5)],
			descriptionHBox => [StyleProp(HorizontalSpacing) => VMIN(2)],
			tcIconBox => [Width => VMIN(16), Height => VMIN(16)],
			tcLabel => [StyleProp(FontSize) => VMIN(5)],
			bracketLabel => [StyleProp(FontSize) => VMIN(5)],
			colorLabel => [StyleProp(FontSize) => VMIN(5)],
			secondSpacer => [Height => VMIN(3.5)],
			acceptBtn => [StyleProp(FontSize) => VMIN(6)]
		];
		fittedComponents = [tcIcon];
    }
}