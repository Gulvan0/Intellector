package gfx.screens;

import haxe.ui.tooltips.ToolTipManager;
import gfx.common.SituationTooltipRenderer;
import struct.ChallengeParams;
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
	private final challengeID:Int;
	
	@:bind(acceptBtn, MouseEvent.CLICK)
	private function onAccepted(e)
	{
		if (LoginManager.isLogged())
			Networker.emitEvent(AcceptOpenChallenge(challengeID, null, null));
		else
		{
			LoginManager.generateOneTimeCredentials();
			Networker.emitEvent(AcceptOpenChallenge(challengeID, LoginManager.getLogin(), LoginManager.getPassword()));
		}
	}

    public function new(id:Int, params:ChallengeParams)
    {
		super();
		this.challengeID = id;

		var timeControlString:String = params.timeControl.toString();
		var timeControlType:TimeControlType = params.timeControl.getType();

		challengeByLabel.text = Dictionary.getPhrase(OPENJOIN_CHALLENGE_BY_HEADER, [params.ownerLogin]);

		tcIcon.resource = AssetManager.timeControlPath(timeControlType);
		tcLabel.text = timeControlString;
		if (timeControlType != Correspondence)
			tcLabel.text += ' (${timeControlType.getName()})';

		bracketLabel.text = Dictionary.getPhrase(params.rated? OPENJOIN_RATED : OPENJOIN_UNRATED);

		colorIcon.resource = AssetManager.challengeColorPath(params.acceptorColor);
		colorIcon.tooltip = switch params.acceptorColor {
			case White: Dictionary.getPhrase(OPENJOIN_COLOR_BLACK_OWNER, [params.ownerLogin]);
			case Black: Dictionary.getPhrase(OPENJOIN_COLOR_WHITE_OWNER, [params.ownerLogin]);
			case null: Dictionary.getPhrase(OPENJOIN_COLOR_RANDOM);
		};

        if (params.customStartingSituation != null)
        {
            customStartPosIcon.hidden = false;
            var renderer:SituationTooltipRenderer = new SituationTooltipRenderer(params.customStartingSituation);
            ToolTipManager.instance.registerTooltip(customStartPosIcon, {
                renderer: renderer
            });
        }
        else
            customStartPosIcon.hidden = true;

		responsiveComponents = [
			challengeByLabel => [StyleProp(FontSize) => VMIN(6)],
			challengeCard => [StyleProp(VerticalSpacing) => VMIN(1.75)],
			descriptionHBox => [StyleProp(HorizontalSpacing) => VMIN(2)],
			tcIconBox => [Width => VMIN(16), Height => VMIN(16)],
			tcLabel => [StyleProp(FontSize) => VMIN(4)],
			bracketLabel => [StyleProp(FontSize) => VMIN(4)],
			paramsBox => [StyleProp(HorizontalSpacing) => VMIN(1.5)],
			paramsLabel => [StyleProp(FontSize) => VMIN(4)],
			colorIcon => [Width => VMIN(4), Height => VMIN(4)],
			customStartPosIcon => [Width => VMIN(4), Height => VMIN(4)],
			acceptBtn => [StyleProp(FontSize) => VMIN(4.5)]
		];
		fittedComponents = [tcIcon];
    }
}