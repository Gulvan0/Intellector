package gfx.popups;

import net.shared.TimeControlType;
import haxe.ui.tooltips.ToolTipManager;
import gfx.common.SituationTooltipRenderer;
import utils.AssetManager;
import dict.Dictionary;
import utils.TimeControl;
import haxe.ui.events.MouseEvent;
import struct.ChallengeParams;
import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/popups/incoming_challenge_popup.xml'))
class IncomingChallengeDialog extends Dialog
{
    private var challengeID:Int;

    @:bind(acceptBtn, MouseEvent.CLICK)
    private function onAccepted(e)
    {
        Networker.emitEvent(AcceptDirectChallenge(challengeID));
    }

    @:bind(declineBtn, MouseEvent.CLICK)
    private function onDeclined(e)
    {
        Networker.emitEvent(DeclineDirectChallenge(challengeID));
    }

    public function new(id:Int, params:ChallengeParams)
    {
        super();
        this.challengeID = id;
        
        var timeControlString:String = params.timeControl.toString();
		var timeControlType:TimeControlType = params.timeControl.getType();

		challengeByLabel.text = Dictionary.getPhrase(INCOMING_CHALLENGE_CHALLENGE_BY_LABEL_TEXT, [params.ownerLogin]);

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
    }
}