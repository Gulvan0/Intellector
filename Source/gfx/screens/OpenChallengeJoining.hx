package gfx.screens;

import gfx.components.Dialogs;
import haxe.ui.core.Screen;
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
class OpenChallengeJoining extends VBox implements IScreen
{
	private final challengeOwner:String;

	public function onEntered()
    {
        ScreenManager.addResizeHandler(redraw);
    }

    public function onClosed()
    {
        ScreenManager.removeResizeHandler(redraw);
	}
	
	private function redraw()
	{
		//TODO: Fill
	}

    public function menuHidden():Bool
    {
        return false;
    }

    public function asComponent():Component
    {
        return this;
	}
	
	@:bind(acceptBtn, MouseEvent.CLICK)
	private function onAccepted(e)
	{
		Dialogs.settings();
		//Networker.emitEvent(AcceptOpenChallenge(challengeOwner));
	}

    public function new(challengeOwner:String, timeControl:TimeControl, color:Null<PieceColor>, rated:Bool = false)
    {
		super();
		this.challengeOwner = challengeOwner;

		challengeByLabel.text = Dictionary.getPhrase(OPENJOIN_CHALLENGE_BY_HEADER, [challengeOwner]);
		tcIcon.resource = AssetManager.timeControlPath(timeControl.getType());
		tcLabel.text = timeControl.toString();
		bracketLabel.text = Dictionary.getPhrase(rated? OPENJOIN_RATED : OPENJOIN_UNRATED);
		colorLabel.text = switch color {
			case White: Dictionary.getPhrase(OPENJOIN_COLOR_WHITE_OWNER, [challengeOwner]);
			case Black: Dictionary.getPhrase(OPENJOIN_COLOR_BLACK_OWNER, [challengeOwner]);
			case null: Dictionary.getPhrase(OPENJOIN_COLOR_RANDOM);
		};
    }
}